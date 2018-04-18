// Swarm upload example code

const {execSync} = require('child_process');

// Swarm instance URL
const SWARM = 'http://localhost:8500/bzz:/';

function publishToSwarm(path) {
  return execSync(`tar -c ${escape(path)} | curl -H "Content-Type: application/x-tar" --data-binary @- ${escape(SWARM)}`)
  .toString('utf8');
};

function excape(value) {
  return JSON.stringify(value);
}

exports.publishToSwarm = publishToSwarm;
