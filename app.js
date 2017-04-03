const express = require('express');

app = express();

app.use(express.static('./'));

app.listen(4000, '0.0.0.0', () => {
  console.log('Documentation server running on port 4000');
});
