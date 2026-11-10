const RELEASE_URL = 'https://github.com/IllyaGIF/repo/releases/download/debs/';
const FORWARDED_HEADERS = ['content-length', 'content-range', 'accept-ranges', 'last-modified', 'etag'];

export async function onRequest(context) {
    const method = context.request.method;
    if (method !== 'GET' && method !== 'HEAD')
        return new Response(null, { status: 405, headers: { allow: 'GET, HEAD' } });

    const segments = Array.isArray(context.params.path) ? context.params.path : [context.params.path];
    const name = segments.join('/');
    if (segments.length !== 1 || !/^[A-Za-z0-9._+~-]+\.deb$/.test(name))
        return new Response('Not found', { status: 404 });

    const requestHeaders = new Headers();
    const range = context.request.headers.get('range');
    if (range)
        requestHeaders.set('range', range);

    const upstream = await fetch(RELEASE_URL + encodeURIComponent(name), { method, headers: requestHeaders, redirect: 'follow' });
    if (upstream.status !== 200 && upstream.status !== 206)
        return new Response('Not found', { status: upstream.status === 404 ? 404 : 502 });

    const headers = new Headers({ 'content-type': 'application/vnd.debian.binary-package' });
    for (const key of FORWARDED_HEADERS) {
        const value = upstream.headers.get(key);
        if (value)
            headers.set(key, value);
    }
    return new Response(method === 'HEAD' ? null : upstream.body, { status: upstream.status, headers });
}
