module.exports = {
  apps: [
    {
      name: 'shiksha-verse-api',
      script: 'src/index.js',
      instances: 'max',       // One per CPU core
      exec_mode: 'cluster',
      watch: false,
      max_memory_restart: '400M',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      error_file: './logs/pm2-error.log',
      out_file: './logs/pm2-out.log',
      merge_logs: true,
    },
  ],
};
