#!/usr/bin/env node

// Export strategy data from Supabase to JSON files for bundling in the iOS app

const https = require('https');
const fs = require('fs');
const path = require('path');

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
    'jacks-or-better-9-6': { displayName: 'Jacks or Better 9/6', filename: 'strategy_jacks_or_better_9_6' },
    'double-double-bonus-9-6': { displayName: 'Double Double Bonus 9/6', filename: 'strategy_double_double_bonus_9_6' },
    'triple-double-bonus-9-6': { displayName: 'Triple Double Bonus 9/6', filename: 'strategy_triple_double_bonus_9_6' },
    'deuces-wild-nsud': { displayName: 'Deuces Wild NSUD', filename: 'strategy_deuces_wild_nsud' },
    'bonus-poker-8-5': { displayName: 'Bonus Poker 8/5', filename: 'strategy_bonus_poker_8_5' },
};

const OUTPUT_DIR = path.join(__dirname, '..', 'ios-native', 'VideoPokerTrainer', 'VideoPokerTrainer', 'Resources');

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

async function exportPaytable(paytableId) {
    const config = paytableConfigs[paytableId];
    if (!config) {
        console.error(`Unknown paytable: ${paytableId}`);
        return;
    }

    console.log(`\nExporting ${config.displayName}...`);

    try {
        const strategies = await fetchAllStrategiesPaginated(paytableId);

        if (strategies.length === 0) {
            console.log(`  No strategies found for ${paytableId}`);
            return;
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

        const outputPath = path.join(OUTPUT_DIR, `${config.filename}.json`);
        fs.writeFileSync(outputPath, JSON.stringify(output, null, 2));

        console.log(`  Exported ${strategies.length} strategies to ${config.filename}.json`);
    } catch (error) {
        console.error(`  Error: ${error.message}`);
    }
}

async function main() {
    const args = process.argv.slice(2);

    if (args.length === 0) {
        console.log('Usage: node export_strategy.js <paytable-id> [paytable-id...]');
        console.log('       node export_strategy.js --all');
        console.log('\nAvailable paytables:');
        for (const [id, config] of Object.entries(paytableConfigs)) {
            console.log(`  ${id} - ${config.displayName}`);
        }
        process.exit(1);
    }

    // Ensure output directory exists
    if (!fs.existsSync(OUTPUT_DIR)) {
        fs.mkdirSync(OUTPUT_DIR, { recursive: true });
    }

    console.log('=== Strategy Export Tool ===');
    console.log(`Output directory: ${OUTPUT_DIR}`);

    if (args[0] === '--all') {
        for (const paytableId of Object.keys(paytableConfigs)) {
            await exportPaytable(paytableId);
        }
    } else {
        for (const paytableId of args) {
            await exportPaytable(paytableId);
        }
    }

    console.log('\nDone!');
}

main().catch(console.error);
