# Implementation Plan: WG-Easy Global Bandwidth Limiting

**Plan ID:** 251229-1531-wg-bandwidth-limit
**Created:** 2025-12-29
**Status:** In Progress
**Brainstorm:** `plans/reports/brainstorm-251229-1531-wg-bandwidth-limit.md`

---

## Overview

Add global bandwidth limiting to wg-easy using Linux Traffic Control (tc). When WireGuard interface starts, automatically apply download/upload limits via HTB qdisc.

### Key Decisions
- **Limit Type:** Global (all clients share same limit)
- **Enforcement:** Hard limit via tc HTB qdisc
- **Portability:** Full via SQLite volume mount
- **IFB Handling:** Runtime check, warn if missing, graceful fallback
- **Burst:** None (rate = ceil)

---

## Phases

| Phase | Name | Description |
|-------|------|-------------|
| 1 | Database Layer | Add bandwidth fields to general_table + migration | DONE (2025-12-29)
| 2 | TC Utility | Create bandwidth.ts for tc command generation |
| 3 | Hook Integration | Inject tc commands into wgHelper.ts |
| 4 | API Layer | Update general API endpoints for new fields |
| 5 | Frontend UI | Add bandwidth settings in admin general page |
| 6 | Testing & Docs | Manual testing, verify container portability |

---

## Phase 1: Database Layer

### Files to Modify

| File | Action |
|------|--------|
| `src/server/database/repositories/general/schema.ts` | Add 3 columns |
| `src/server/database/repositories/general/types.ts` | Add Zod schemas |
| `src/server/database/repositories/general/service.ts` | Add getBandwidthConfig() |
| `src/server/database/migrations/0003_bandwidth_limit.sql` | New migration |

### Schema Changes

```typescript
// Add to schema.ts after metricsPassword
bandwidthEnabled: int('bandwidth_enabled', { mode: 'boolean' }).notNull().default(false),
downloadLimitMbps: int('download_limit_mbps').notNull().default(0),
uploadLimitMbps: int('upload_limit_mbps').notNull().default(0),
```

### Migration SQL

```sql
-- 0003_bandwidth_limit.sql
ALTER TABLE `general_table` ADD `bandwidth_enabled` integer DEFAULT 0 NOT NULL;
ALTER TABLE `general_table` ADD `download_limit_mbps` integer DEFAULT 0 NOT NULL;
ALTER TABLE `general_table` ADD `upload_limit_mbps` integer DEFAULT 0 NOT NULL;
```

### Types Update

```typescript
// Add to types.ts
const bandwidthEnabled = z.boolean({ message: t('zod.general.bandwidthEnabled') });
const bandwidthLimit = z.number({ message: t('zod.general.bandwidthLimit') }).min(0);

// Update GeneralUpdateSchema
export const GeneralUpdateSchema = z.object({
  sessionTimeout: sessionTimeout,
  metricsPrometheus: metricsEnabled,
  metricsJson: metricsEnabled,
  metricsPassword: metricsPassword,
  bandwidthEnabled: bandwidthEnabled,
  downloadLimitMbps: bandwidthLimit,
  uploadLimitMbps: bandwidthLimit,
});
```

### Service Update

```typescript
// Add to service.ts createPreparedStatement()
getBandwidthConfig: db.query.general
  .findFirst({
    columns: {
      bandwidthEnabled: true,
      downloadLimitMbps: true,
      uploadLimitMbps: true,
    },
  })
  .prepare(),

// Add new method to GeneralService
async getBandwidthConfig() {
  const result = await this.#statements.getBandwidthConfig.execute();
  if (!result) throw new Error('General Config not found');
  return result;
}

// Update getConfig() to include new fields
```

---

## Phase 2: TC Utility

### New File: `src/server/utils/bandwidth.ts`

```typescript
import debug from 'debug';

const BW_DEBUG = debug('Bandwidth');

export interface BandwidthConfig {
  enabled: boolean;
  downloadMbps: number;
  uploadMbps: number;
}

export interface TcCommands {
  postUp: string;
  postDown: string;
}

/**
 * Check if IFB kernel module is available
 */
export async function checkIfbAvailable(): Promise<boolean> {
  try {
    await exec('modprobe ifb 2>/dev/null || lsmod | grep -q ifb');
    return true;
  } catch {
    BW_DEBUG('IFB module not available');
    return false;
  }
}

/**
 * Generate tc commands for bandwidth limiting
 * @param interfaceName - WireGuard interface name (e.g., wg0)
 * @param config - Bandwidth configuration
 * @param ifbAvailable - Whether IFB module is available for upload limiting
 */
export function generateTcCommands(
  interfaceName: string,
  config: BandwidthConfig,
  ifbAvailable: boolean = true
): TcCommands {
  if (!config.enabled || (config.downloadMbps === 0 && config.uploadMbps === 0)) {
    return { postUp: '', postDown: '' };
  }

  const postUpParts: string[] = [];
  const postDownParts: string[] = [];

  // Download limit (egress on wg interface)
  if (config.downloadMbps > 0) {
    postUpParts.push(
      `tc qdisc add dev ${interfaceName} root handle 1: htb default 10`,
      `tc class add dev ${interfaceName} parent 1: classid 1:1 htb rate ${config.downloadMbps}mbit ceil ${config.downloadMbps}mbit`,
      `tc class add dev ${interfaceName} parent 1:1 classid 1:10 htb rate ${config.downloadMbps}mbit ceil ${config.downloadMbps}mbit`
    );
    postDownParts.push(`tc qdisc del dev ${interfaceName} root 2>/dev/null || true`);
  }

  // Upload limit (ingress via IFB mirror)
  if (config.uploadMbps > 0 && ifbAvailable) {
    const ifbDev = 'ifb0';
    postUpParts.push(
      `ip link add ${ifbDev} type ifb 2>/dev/null || true`,
      `ip link set ${ifbDev} up`,
      `tc qdisc add dev ${interfaceName} handle ffff: ingress`,
      `tc filter add dev ${interfaceName} parent ffff: protocol all u32 match u32 0 0 action mirred egress redirect dev ${ifbDev}`,
      `tc qdisc add dev ${ifbDev} root handle 1: htb default 10`,
      `tc class add dev ${ifbDev} parent 1: classid 1:1 htb rate ${config.uploadMbps}mbit ceil ${config.uploadMbps}mbit`,
      `tc class add dev ${ifbDev} parent 1:1 classid 1:10 htb rate ${config.uploadMbps}mbit ceil ${config.uploadMbps}mbit`
    );
    postDownParts.push(
      `tc qdisc del dev ${interfaceName} handle ffff: ingress 2>/dev/null || true`,
      `ip link del ${ifbDev} 2>/dev/null || true`
    );
  }

  return {
    postUp: postUpParts.join('; '),
    postDown: postDownParts.join('; '),
  };
}
```

---

## Phase 3: Hook Integration

### Modify: `src/server/utils/wgHelper.ts`

**Changes:**
1. Import `generateTcCommands` from bandwidth.ts
2. Modify `generateServerInterface()` to accept bandwidth config
3. Append tc commands to PostUp/PostDown

```typescript
// Add import
import { generateTcCommands, type BandwidthConfig } from './bandwidth';

// Modify generateServerInterface signature
generateServerInterface: (
  wgInterface: InterfaceType,
  hooks: HooksType,
  options: Options & { bandwidth?: BandwidthConfig; ifbAvailable?: boolean } = {}
) => {
  // ... existing code ...

  // Generate tc commands if bandwidth config provided
  let tcPostUp = '';
  let tcPostDown = '';
  if (options.bandwidth) {
    const tcCommands = generateTcCommands(
      wgInterface.name,
      options.bandwidth,
      options.ifbAvailable ?? true
    );
    tcPostUp = tcCommands.postUp;
    tcPostDown = tcCommands.postDown;
  }

  // Append to hooks
  const finalPostUp = [iptablesTemplate(hooks.postUp, wgInterface), tcPostUp]
    .filter(Boolean)
    .join('; ');
  const finalPostDown = [iptablesTemplate(hooks.postDown, wgInterface), tcPostDown]
    .filter(Boolean)
    .join('; ');

  return `# Note: Do not edit this file directly.
# Your changes will be overwritten!

# Server
[Interface]
PrivateKey = ${wgInterface.privateKey}
Address = ${address}
ListenPort = ${wgInterface.port}
MTU = ${wgInterface.mtu}
${extraLines.length ? `${extraLines.join('\n')}\n` : ''}
PreUp = ${iptablesTemplate(hooks.preUp, wgInterface)}
PostUp = ${finalPostUp}
PreDown = ${iptablesTemplate(hooks.preDown, wgInterface)}
PostDown = ${finalPostDown}`;
}
```

### Modify: `src/server/utils/WireGuard.ts`

**Changes:**
1. Fetch bandwidth config in `#saveWireguardConfig()`
2. Check IFB availability at startup
3. Pass config to `generateServerInterface()`

```typescript
// Add to WireGuard class
#ifbAvailable: boolean = true;

async Startup() {
  // ... existing code ...

  // Check IFB availability for upload limiting
  this.#ifbAvailable = await checkIfbAvailable();
  if (!this.#ifbAvailable) {
    WG_DEBUG('IFB module not available - upload limiting disabled');
  }

  // ... rest of startup ...
}

async #saveWireguardConfig(wgInterface: InterfaceType) {
  const clients = await Database.clients.getAll();
  const hooks = await Database.hooks.get();
  const bandwidthConfig = await Database.general.getBandwidthConfig();

  const result = [];
  result.push(
    wg.generateServerInterface(wgInterface, hooks, {
      enableIpv6: !WG_ENV.DISABLE_IPV6,
      bandwidth: {
        enabled: bandwidthConfig.bandwidthEnabled,
        downloadMbps: bandwidthConfig.downloadLimitMbps,
        uploadMbps: bandwidthConfig.uploadLimitMbps,
      },
      ifbAvailable: this.#ifbAvailable,
    })
  );
  // ... rest unchanged ...
}
```

---

## Phase 4: API Layer

### Modify: `src/server/api/admin/general.get.ts`

No changes needed - `getConfig()` already returns all fields from general_table. Just need to update the prepared statement in service.ts to include new columns.

### Modify: `src/server/api/admin/general.post.ts`

No changes needed - uses `GeneralUpdateSchema` which will be updated in types.ts.

### New Endpoint (Optional): `src/server/api/admin/bandwidth-status.get.ts`

```typescript
export default definePermissionEventHandler('admin', 'any', async () => {
  const ifbAvailable = await checkIfbAvailable();
  const config = await Database.general.getBandwidthConfig();

  return {
    enabled: config.bandwidthEnabled,
    downloadLimitMbps: config.downloadLimitMbps,
    uploadLimitMbps: config.uploadLimitMbps,
    ifbAvailable,
    uploadLimitActive: config.bandwidthEnabled && config.uploadLimitMbps > 0 && ifbAvailable,
  };
});
```

---

## Phase 5: Frontend UI

### Modify: `src/app/pages/admin/general.vue`

Add new FormGroup after metrics section:

```vue
<FormGroup>
  <FormHeading>{{ $t('admin.general.bandwidth') }}</FormHeading>
  <FormSwitchField
    id="bandwidthEnabled"
    v-model="data.bandwidthEnabled"
    :label="$t('admin.general.bandwidthEnabled')"
    :description="$t('admin.general.bandwidthEnabledDesc')"
  />
  <FormNumberField
    v-if="data.bandwidthEnabled"
    id="downloadLimit"
    v-model="data.downloadLimitMbps"
    :label="$t('admin.general.downloadLimit')"
    :description="$t('admin.general.downloadLimitDesc')"
  />
  <FormNumberField
    v-if="data.bandwidthEnabled"
    id="uploadLimit"
    v-model="data.uploadLimitMbps"
    :label="$t('admin.general.uploadLimit')"
    :description="$t('admin.general.uploadLimitDesc')"
  />
  <!-- Optional: IFB warning -->
  <div v-if="data.bandwidthEnabled && data.uploadLimitMbps > 0 && !ifbAvailable"
       class="text-yellow-600 dark:text-yellow-400 text-sm">
    {{ $t('admin.general.ifbWarning') }}
  </div>
</FormGroup>
```

### Modify: `src/i18n/locales/en.json`

Add translations under `admin.general`:

```json
"bandwidth": "Bandwidth Limiting",
"bandwidthEnabled": "Enable Bandwidth Limiting",
"bandwidthEnabledDesc": "Apply global bandwidth limits to all VPN traffic",
"downloadLimit": "Download Limit (Mbps)",
"downloadLimitDesc": "Maximum download speed for clients (0 = unlimited)",
"uploadLimit": "Upload Limit (Mbps)",
"uploadLimitDesc": "Maximum upload speed from clients (0 = unlimited)",
"ifbWarning": "Upload limiting requires IFB kernel module which is not available on this host"
```

Also add under `zod.general`:
```json
"bandwidthEnabled": "Bandwidth Enabled",
"bandwidthLimit": "Bandwidth Limit"
```

### Update Other Locale Files

Copy translations to all locale files in `src/i18n/locales/`:
- vi.json, zh-CN.json, de.json, fr.json, etc.

---

## Phase 6: Testing & Verification

### Manual Test Checklist

1. **Migration Test**
   - [ ] Fresh install: tables created with default values
   - [ ] Existing DB: migration adds columns without data loss

2. **UI Test**
   - [ ] Toggle appears in Admin > General
   - [ ] Number fields show only when enabled
   - [ ] Save/Revert works correctly
   - [ ] IFB warning shows when applicable

3. **TC Command Test**
   - [ ] Enable with download=10, upload=5
   - [ ] Check: `tc qdisc show dev wg0` shows HTB
   - [ ] Check: `tc class show dev wg0` shows rate limits
   - [ ] Disable bandwidth limiting
   - [ ] Check: tc rules removed

4. **Container Restart Test**
   - [ ] Enable limits, restart container
   - [ ] Verify limits reapplied after restart
   - [ ] Settings persist in DB

5. **Portability Test**
   - [ ] Copy volume to new server
   - [ ] Deploy container with mounted volume
   - [ ] Verify settings preserved

6. **Speed Test**
   - [ ] Set download limit to 10 Mbps
   - [ ] Run speed test through VPN
   - [ ] Verify speed ~10 Mbps (±10%)

---

## File Summary

| File | Action | Phase |
|------|--------|-------|
| `src/server/database/repositories/general/schema.ts` | Modify | 1 |
| `src/server/database/repositories/general/types.ts` | Modify | 1 |
| `src/server/database/repositories/general/service.ts` | Modify | 1 |
| `src/server/database/migrations/0003_bandwidth_limit.sql` | New | 1 |
| `src/server/utils/bandwidth.ts` | New | 2 |
| `src/server/utils/wgHelper.ts` | Modify | 3 |
| `src/server/utils/WireGuard.ts` | Modify | 3 |
| `src/server/api/admin/bandwidth-status.get.ts` | New (Optional) | 4 |
| `src/app/pages/admin/general.vue` | Modify | 5 |
| `src/i18n/locales/*.json` | Modify | 5 |

**Total: ~10 files, ~300 lines of new code**

---

## Dependencies

- No new npm packages required
- Container already includes: iproute2 (tc), iptables, kmod
- Host must support IFB module for upload limiting (graceful fallback if missing)

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| IFB not available | Runtime check + warn, upload limit disabled |
| TC commands fail | Wrap in `|| true`, log errors, VPN still works |
| Very low limit set | UI can add min validation (e.g., 1 Mbps) |
| DB migration fails | Use safe ALTER TABLE, test on backup first |

---

## Success Criteria

1. ✅ Bandwidth settings visible in Admin > General
2. ✅ TC rules applied when interface starts
3. ✅ Actual bandwidth matches config (±10%)
4. ✅ Settings persist across container restarts
5. ✅ Container portable with volume mount
6. ✅ Graceful handling when IFB unavailable
