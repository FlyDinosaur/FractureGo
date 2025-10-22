module.exports = {
  apps: [{
    name: 'fracturego-server',
    script: 'src/server.js',
    cwd: '/opt/fracturego/fracturego-server',
    instances: 'max',
    exec_mode: 'cluster',
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 28974
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 28974
    },
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    restart_delay: 4000,
    kill_timeout: 3000,
    listen_timeout: 3000,
    shutdown_with_message: true
  }],

  deploy: {
    production: {
      user: 'fracturego',
      host: ['your-server-ip'],
      ref: 'origin/main',
      repo: 'https://github.com/FlyDinosaur/FractureGo-Server.git',
      path: '/opt/fracturego/fracturego-server',
      'pre-deploy-local': '',
      'post-deploy': 'npm install --production && npm run migrate && pm2 reload ecosystem.config.js --env production',
      'pre-setup': '',
      'post-setup': 'npm install --production && npm run migrate',
      env: {
        NODE_ENV: 'production',
        PORT: 28974
      }
    }
  }
}; 