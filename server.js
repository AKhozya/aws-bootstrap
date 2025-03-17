const { hostname } = require('os');
const http = require('http');
const https = require('https'); 
const fs = require('fs');

const STACK_NAME = process.env.STACK_NAME || "Unknown Stack";
const port = 8080;
const httpsPort = 8443; 
const httpsKey = '../keys/key.pem' 
const httpsCert = '../keys/cert.pem' 

// Create log directory if it doesn't exist
const logDir = '/home/ec2-user/logs';
if (!fs.existsSync(logDir)){
  fs.mkdirSync(logDir, { recursive: true });
}

// Setup logging
const log = (message) => {
  const timestamp = new Date().toISOString();
  const logMessage = `${timestamp} - ${message}\n`;
  fs.appendFileSync(`${logDir}/server.log`, logMessage);
  console.log(message);
};

log(`Starting server in ${STACK_NAME}`);

if (fs.existsSync(httpsKey) && fs.existsSync(httpsCert)) { 
  log('Starting https server')
  const message = `Hello HTTPS World from ${hostname()} in ${STACK_NAME}\n`;
  const options = { key: fs.readFileSync(httpsKey), cert: fs.readFileSync(httpsCert) };
  const server = https.createServer(options, (req, res) => { 
    log(`Request received: ${req.url}`);
    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/plain');
    res.end(message);
  });
  server.listen(httpsPort, '0.0.0.0', () => {
    log(`Server running at http://${hostname()}:${httpsPort}/`);
  });
}

log('Starting http server')
const server = http.createServer((req, res) => { 
  const message = `!!!Hello World!!! from ${hostname()} in ${STACK_NAME}\n`;
  log(`Request received: ${req.url}`);
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end(message);
});

// Listen on all interfaces (0.0.0.0) not just localhost
server.listen(port, '0.0.0.0', () => {
  log(`Server running at http://${hostname()}:${port}/`);
});