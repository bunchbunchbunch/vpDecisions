const fs = require('fs');
const csv = require('csv-parser');
const { createObjectCsvWriter } = require('csv-writer');

const uniquePairs = [];
const seenPairs = new Set();

fs.createReadStream('jacks_or_better_9_6_standard.csv')
  .pipe(csv())
  .on('data', (row) => {
    const description = row.description;
    const bestEv = row.best_ev;
    const pairKey = `${description}|${bestEv}`;

    if (!seenPairs.has(pairKey)) {
      seenPairs.add(pairKey);
      uniquePairs.push({
        description: description,
        best_ev: bestEv
      });
    }
  })
  .on('end', () => {
    console.log(`Found ${uniquePairs.length} unique description/EV pairs`);

    const csvWriter = createObjectCsvWriter({
      path: 'unique_description_ev_pairs.csv',
      header: [
        { id: 'description', title: 'description' },
        { id: 'best_ev', title: 'best_ev' }
      ]
    });

    csvWriter.writeRecords(uniquePairs)
      .then(() => {
        console.log(`Exported to unique_description_ev_pairs.csv`);
        console.log(`Total unique pairs: ${uniquePairs.length}`);
      });
  });
