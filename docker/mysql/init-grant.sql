-- Conceder a 'enarm' permisos sobre todas las bases enarmapi_* (development y test)
GRANT ALL PRIVILEGES ON `enarmapi_%`.* TO 'enarm'@'%';
FLUSH PRIVILEGES;
