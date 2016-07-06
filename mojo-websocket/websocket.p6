use Mojolicious::Lite:from<Perl5>;

websocket '/console' => -> $c {
    $c.inactivity_timeout: 60*60;
    state $shell = do with Proc::Async.new: '/bin/sh', :w {
        .stdout.tap: { $c.send: $^v        }
        .stderr.tap: { $c.send: "ERR: $^v" }
        .start;
        $_;
    }

    $c.on: message => {
        $^c.send: "> $^msg\n";
        $shell.write: "$^msg\n".encode;
    }
}

get '/' => *.render: inline => q:to/END/;
    <!DOCTYPE html>
    <meta charset="utf-8">
    <title>Console</title>
    <script>
        window.onload = function() {
            var ws = new WebSocket('<%= url_for('console')->to_abs %>');
            ws.onmessage = function (event) {
                document.getElementById('console').innerHTML += event.data;
            };
            document.getElementById('command').focus();
            document.getElementById('send').onsubmit = function() {
                ws.send( document.getElementById('command').value );
                document.getElementById('command').value = '';
                return false;
            }
        }
    </script>
    <style>
        body * {
            font-family: monospace;
            white-space: pre;
        }
        #console {
            background: #000;
            color: #ccc;
        }
    </style>
    <div id="console"></div>
    <form id="send"><input id="command"></form>
    END

app.start;
