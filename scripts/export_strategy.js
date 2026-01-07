#!/usr/bin/env node

// Export strategy data from Supabase to JSON files for bundling in the iOS app
// Outputs compressed .json.gz files ready for upload to Supabase Storage

const https = require('https');
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

// Expected number of unique 5-card poker hands
const EXPECTED_HAND_COUNT = 204087;

// Simple .env parser
function loadEnv(envPath) {
    const content = fs.readFileSync(envPath, 'utf-8');
    const env = {};
    for (const line of content.split('\n')) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith('#')) continue;
        const [key, ...valueParts] = trimmed.split('=');
        if (key && valueParts.length > 0) {
            env[key.trim()] = valueParts.join('=').trim();
        }
    }
    return env;
}

const envVars = loadEnv(path.join(__dirname, '..', '.env'));
const SUPABASE_URL = envVars.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = envVars.SUPABASE_SERVICE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    console.error('Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in .env');
    process.exit(1);
}

const paytableConfigs = {
    'jacks-or-better-9-6': { displayName: 'Jacks or Better 9/6', filename: 'strategy_jacks_or_better_9_6', bundled: true },
    'double-double-bonus-9-6': { displayName: 'Double Double Bonus 9/6', filename: 'strategy_double_double_bonus_9_6', bundled: true },
    'triple-double-bonus-9-6': { displayName: 'Triple Double Bonus 9/6', filename: 'strategy_triple_double_bonus_9_6', bundled: true },
    'deuces-wild-nsud': { displayName: 'Deuces Wild NSUD', filename: 'strategy_deuces_wild_nsud', bundled: true },
    'bonus-poker-8-5': { displayName: 'Bonus Poker 8/5', filename: 'strategy_bonus_poker_8_5', bundled: false },
    'double-bonus-10-7': { displayName: 'Double Bonus 10/7', filename: 'strategy_double_bonus_10_7', bundled: false },
    'deuces-wild-full-pay': { displayName: 'Deuces Wild Full Pay', filename: 'strategy_deuces_wild_full_pay', bundled: false },
};

// Output directories
const BUNDLE_DIR = path.join(__dirname, '..', 'ios-native', 'VideoPokerTrainer', 'VideoPokerTrainer', 'Resources');
const UPLOAD_DIR = path.join(__dirname, '..', 'supabase-uploads');

async function fetchAllStrategies(paytableId) {
    const url = new URL(`${SUPABASE_URL}/rest/v1/strategy`);
    url.searchParams.set('paytable_id', `eq.${paytableId}`);
    url.searchParams.set('select', 'hand_key,best_hold,best_ev,hold_evs');

    return new Promise((resolve, reject) => {
        const options = {
            hostname: url.hostname,
            path: url.pathname + url.search,
            method: 'GET',
            headers: {
                'apikey': SUPABASE_SERVICE_KEY,
                'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
                'Content-Type': 'application/json',
                'Prefer': 'count=exact'
            }
        };

        console.log(`  Fetching from ${url.pathname}...`);

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode !== 200) {
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                    return;
                }
                try {
                    const count = res.headers['content-range'];
                    console.log(`  Content-Range: ${count}`);
                    resolve(JSON.parse(data));
                } catch (e) {
                    reject(e);
                }
            });
        });

        req.on('error', reject);
        req.end();
    });
}

// Supabase limits responses to 1000 rows - need to paginate
async function fetchAllStrategiesPaginated(paytableId, pageSize = 1000) {
    let allStrategies = [];
    let offset = 0;
    let hasMore = true;

    while (hasMore) {
        const url = new URL(`${SUPABASE_URL}/rest/v1/strategy`);
        url.searchParams.set('paytable_id', `eq.${paytableId}`);
        url.searchParams.set('select', 'hand_key,best_hold,best_ev,hold_evs');
        url.searchParams.set('order', 'hand_key');
        url.searchParams.set('limit', pageSize.toString());
        url.searchParams.set('offset', offset.toString());

        const strategies = await new Promise((resolve, reject) => {
            const options = {
                hostname: url.hostname,
                path: url.pathname + url.search,
                method: 'GET',
                headers: {
                    'apikey': SUPABASE_SERVICE_KEY,
                    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
                    'Content-Type': 'application/json'
                }
            };

            const req = https.request(options, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => {
                    if (res.statusCode !== 200) {
                        reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                        return;
                    }
                    try {
                        resolve(JSON.parse(data));
                    } catch (e) {
                        reject(e);
                    }
                });
            });

            req.on('error', reject);
            req.end();
        });

        allStrategies = allStrategies.concat(strategies);
        console.log(`  Fetched ${allStrategies.length} strategies...`);

        if (strategies.length < pageSize) {
            hasMore = false;
        } else {
            offset += pageSize;
        }
    }

    return allStrategies;
}

async function exportPaytable(paytableId, options = {}) {
    const config = paytableConfigs[paytableId];
    if (!config) {
        console.error(`Unknown paytable: ${paytableId}`);
        return { success: false, error: 'Unknown paytable' };
    }

    console.log(`\nExporting ${config.displayName}...`);

    try {
        const strategies = await fetchAllStrategiesPaginated(paytableId);

        if (strategies.length === 0) {
            console.log(`  ❌ No strategies found for ${paytableId}`);
            return { success: false, error: 'No strategies found' };
        }

        // Validate row count
        if (strategies.length !== EXPECTED_HAND_COUNT) {
            console.log(`  ❌ VALIDATION FAILED: Expected ${EXPECTED_HAND_COUNT} rows, got ${strategies.length}`);
            if (!options.force) {
                console.log(`  Use --force to export anyway`);
                return { success: false, error: `Row count mismatch: ${strategies.length}` };
            }
            console.log(`  ⚠️  Continuing due to --force flag`);
        } else {
            console.log(`  ✅ Row count validated: ${strategies.length} rows`);
        }

        // Convert to the format expected by LocalStrategyStore
        const output = {
            game: config.displayName,
            paytable_id: paytableId,
            version: 1,
            generated: new Date().toISOString(),
            hand_count: strategies.length,
            strategies: {}
        };

        for (const s of strategies) {
            output.strategies[s.hand_key] = {
                hold: s.best_hold,
                ev: s.best_ev
            };
            // Include hold_evs if present
            if (s.hold_evs && Object.keys(s.hold_evs).length > 0) {
                output.strategies[s.hand_key].hold_evs = s.hold_evs;
            }
        }

        const jsonString = JSON.stringify(output);
        const jsonSize = Buffer.byteLength(jsonString, 'utf8');

        // Compress with gzip
        const compressed = zlib.gzipSync(jsonString, { level: 9 });
        const compressedSize = compressed.length;
        const ratio = ((1 - compressedSize / jsonSize) * 100).toFixed(1);

        console.log(`  JSON size: ${(jsonSize / 1024 / 1024).toFixed(2)} MB`);
        console.log(`  Compressed: ${(compressedSize / 1024 / 1024).toFixed(2)} MB (${ratio}% reduction)`);

        // Determine output directory
        const outputDir = config.bundled ? BUNDLE_DIR : UPLOAD_DIR;
        const outputPath = path.join(outputDir, `${config.filename}.json.gz`);

        fs.writeFileSync(outputPath, compressed);
        console.log(`  ✅ Exported to ${outputPath}`);

        // Also write to upload dir for all paytables (for backup/consistency)
        if (config.bundled && options.uploadAll) {
            const uploadPath = path.join(UPLOAD_DIR, `${config.filename}.json.gz`);
            fs.writeFileSync(uploadPath, compressed);
            console.log(`  ✅ Also copied to ${uploadPath}`);
        }

        return { success: true, rowCount: strategies.length };
    } catch (error) {
        console.error(`  ❌ Error: ${error.message}`);
        return { success: false, error: error.message };
    }
}

async function main() {
    const args = process.argv.slice(2);

    // Parse flags
    const flags = {
        all: args.includes('--all'),
        bundled: args.includes('--bundled'),
        downloadable: args.includes('--downloadable'),
        force: args.includes('--force'),
        uploadAll: args.includes('--upload-all'),
    };
    const paytableIds = args.filter(a => !a.startsWith('--'));

    if (!flags.all && !flags.bundled && !flags.downloadable && paytableIds.length === 0) {
        console.log('Usage: node export_strategy.js [options] [paytable-id...]');
        console.log('\nOptions:');
        console.log('  --all          Export all paytables');
        console.log('  --bundled      Export only bundled paytables (included in app)');
        console.log('  --downloadable Export only downloadable paytables (Supabase Storage)');
        console.log('  --force        Export even if row count validation fails');
        console.log('  --upload-all   Also copy bundled paytables to upload directory');
        console.log('\nAvailable paytables:');
        for (const [id, config] of Object.entries(paytableConfigs)) {
            const type = config.bundled ? '(bundled)' : '(downloadable)';
            console.log(`  ${id} - ${config.displayName} ${type}`);
        }
        console.log(`\nExpected row count: ${EXPECTED_HAND_COUNT}`);
        process.exit(1);
    }

    // Ensure output directories exist
    if (!fs.existsSync(BUNDLE_DIR)) {
        fs.mkdirSync(BUNDLE_DIR, { recursive: true });
    }
    if (!fs.existsSync(UPLOAD_DIR)) {
        fs.mkdirSync(UPLOAD_DIR, { recursive: true });
    }

    console.log('=== Strategy Export Tool ===');
    console.log(`Bundle directory: ${BUNDLE_DIR}`);
    console.log(`Upload directory: ${UPLOAD_DIR}`);
    console.log(`Expected rows: ${EXPECTED_HAND_COUNT}`);

    // Determine which paytables to export
    let idsToExport = [];
    if (flags.all) {
        idsToExport = Object.keys(paytableConfigs);
    } else if (flags.bundled) {
        idsToExport = Object.entries(paytableConfigs)
            .filter(([_, config]) => config.bundled)
            .map(([id]) => id);
    } else if (flags.downloadable) {
        idsToExport = Object.entries(paytableConfigs)
            .filter(([_, config]) => !config.bundled)
            .map(([id]) => id);
    } else {
        idsToExport = paytableIds;
    }

    // Export each paytable
    const results = [];
    for (const paytableId of idsToExport) {
        const result = await exportPaytable(paytableId, {
            force: flags.force,
            uploadAll: flags.uploadAll
        });
        results.push({ paytableId, ...result });
    }

    // Summary
    console.log('\n=== Summary ===');
    const successful = results.filter(r => r.success);
    const failed = results.filter(r => !r.success);

    if (successful.length > 0) {
        console.log(`✅ Successfully exported: ${successful.length}`);
        for (const r of successful) {
            console.log(`   - ${r.paytableId}: ${r.rowCount} rows`);
        }
    }

    if (failed.length > 0) {
        console.log(`❌ Failed: ${failed.length}`);
        for (const r of failed) {
            console.log(`   - ${r.paytableId}: ${r.error}`);
        }
        process.exit(1);
    }

    console.log('\nDone!');
}

main().catch(console.error);
