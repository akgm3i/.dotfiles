#
# deinitialize.
#

()
{
    local f
    for f in ./*secret*.zsh(N-.)
    do
        source "$f"
    done
}

lspider=$(cat << EOF
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
                    :
              ,     :
            ,'      :     '.
          ,;        :      ';,
        ,:'         :        ':.
        ::          :         ;:
       ,:       ,,,,,,,,,      ::
       ::     .:::::::::::.    ::
    ,  ::    :::::::::::::::   ::
   ;   ::   :::::::▄▄▄:::::::  ':   .
  ;    ::   ::::::▐█:▀█::::::   :;   ;
 :'    ::   ::::::▄█▀▀█::::::   :;    ;
::     ':.  ::::::▐█:▪▐▌:::::  ,:     ::
';.     ';;:;::::::▀::▀:::::;,;''    .:'
 ::         ';:::::::::::::;'        ::
  ::.         '::;:::::;::'          :;
   ;:.   ,.,,;;';:::::::;';;,,,.    ,:'
    ':::'''' ,,';:::::::;",, '':::::;'
        ,,,,;' ,;:::::::;, ':,,
     ,,;"'   .:: ':::::' ;:   ";;,,
   .:'      .:;   ;""";  ':.     "';.
   :;      :;:            ';,      ::
   ;      :;.               ;:     ::
   ::    :;                  ;:    ::
    '.  ,;                    ;:  .'
     '  ::                    ::  '
       ,:;                    ::.
       ::'                     :;
       ::                      ::
       ::                      ::
        ;:                    :;
         ';                  ;'
           ;                ;
EOF
)

sspider=$(cat << 'EOF'
    |
    |
    |
    |
    |
    |
    |
    |
  / _ \
\_\(_)/_/
 _//o\\_
  /   \
EOF
)

if [ $LINES -gt 18 ]; then
  printf $lspider
else
  printf $sspider
fi

printf "\n\n"

cat << EOF
            $fg_bold[cyan]This is ZSH $fg_bold[red]$ZSH_VERSION
            $fg_bold[cyan]DISPLAY on $fg_bold[red]$DISPLAY$reset_color
EOF