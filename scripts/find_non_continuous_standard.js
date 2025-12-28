const fs = require('fs');
const csv = require('csv-parser');

const blocks = [];
let currentBlock = null;

fs.createReadStream('jacks_or_better_9_6_standard.csv')
  .pipe(csv())
  .on('data', (row) => {
    const desc = row.description;

    if (!currentBlock || currentBlock.desc !== desc) {
      // Start new block
      if (currentBlock) {
        blocks.push(currentBlock);
      }
      currentBlock = {
        desc: desc,
        startRow: blocks.reduce((sum, b) => sum + b.count, 0) + 1,
        count: 1,
        firstEv: parseFloat(row.best_ev),
        firstHand: row.hand_key
      };
    } else {
      // Continue current block
      currentBlock.count++;
    }
  })
  .on('end', () => {
    if (currentBlock) {
      blocks.push(currentBlock);
    }

    // Find descriptions that appear in multiple blocks
    const descCounts = {};
    blocks.forEach(b => {
      if (!descCounts[b.desc]) {
        descCounts[b.desc] = [];
      }
      descCounts[b.desc].push(b);
    });

    const nonContinuous = Object.entries(descCounts)
      .filter(([desc, blockList]) => blockList.length > 1)
      .sort((a, b) => b[1].length - a[1].length);

    console.log(`Found ${nonContinuous.length} descriptions with non-continuous runs:\n`);

    nonContinuous.forEach(([desc, blockList]) => {
      console.log(`${desc}: appears in ${blockList.length} separate blocks`);
      blockList.forEach((block, i) => {
        console.log(`  Block ${i+1}: rows ${block.startRow}-${block.startRow + block.count - 1} (${block.count} rows, EV=${block.firstEv})`);
      });
      console.log();
    });
  });
