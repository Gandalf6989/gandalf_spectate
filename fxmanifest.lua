fx_version 'adamant'
game 'gta5'

shared_script 'config.lua'

server_script 'server/main.lua'
 
client_script 'client/main.lua'

ui_page {
  'ui/index.html'
}

files {
  'ui/index.html',
  'ui/style.css',
  'ui/main.js',
}
