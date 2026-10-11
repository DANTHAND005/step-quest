def preflight(client, origin):
    return client.options("/me", headers={
        "Origin": origin,
        "Access-Control-Request-Method": "GET",
        "Access-Control-Request-Headers": "authorization",
    })


def test_localhost_page_allowed(client):
    r = preflight(client, "http://localhost:51234")
    assert r.headers.get("access-control-allow-origin") == "http://localhost:51234"


def test_other_sites_blocked(client):
    r = preflight(client, "https://evil.example")
    assert "access-control-allow-origin" not in r.headers
