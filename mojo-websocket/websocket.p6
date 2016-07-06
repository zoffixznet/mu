use Mojolicious::Lite:from<Perl5>;

get '/' => 'index';

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

app.start;
