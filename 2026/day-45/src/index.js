const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

/* Serve static frontend */
app.use(express.static(path.join(__dirname, '../public')));

/* Health endpoint */
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    commit: process.env.GIT_SHA || 'local',
    buildDate: process.env.BUILD_DATE || 'local'
  });
});

/* API route */
app.get('/api', (req, res) => {
  res.json({
    message: 'Docker CI/CD Pipeline Running Successfully 🚀'
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
