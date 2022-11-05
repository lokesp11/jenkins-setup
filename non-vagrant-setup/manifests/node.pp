node default {
  case $facts['os']['name'] {
    'Ubuntu': {
       include jenkins
        }
     default: { notify  { 'os_issue':
                           message => "OS not supported"
                        }
        }
   }
}