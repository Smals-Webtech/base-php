vcl 4.1;

backend default {
    .host = "prime";
    .port = "9000";
} 

sub vcl_recv {
    if (req.url == "/varnish-health") {
        return (synth(200, "OK"));
    }
}

sub vcl_synth {
    if (resp.status == 200 && resp.reason == "OK") {
        set resp.http.Content-Type = "text/plain";
        synthetic("OK");
        return (deliver);
    }
}