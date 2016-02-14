# -*- coding: utf-8 -*-
def _vital_vim_network_http_define():
    import sys
    import copy
    import gzip
    import time
    import functools
    import collections

    try:
        from gzip import decompress as gzip_decompress
    except ImportError:
        try:
            from io import ByteIO as StringIO
        except ImportError:
            from StringIO import StringIO
        from gzip import GzipFile
        def gzip_decompress(data):
            buf = StringIO(data)
            f = GzipFile(fileobj=buf)
            return f.read()[:]

    try:
        from urllib.request import (
            build_opener,
            Request,
            HTTPPasswordMgrWithDefaultRealm,
            HTTPRedirectHandler,
            HTTPBasicAuthHandler,
            HTTPDigestAuthHandler,
            HTTPError, URLError,
        )
    except ImportError:
        # Python 2
        import urllib2
        class Request(urllib2.Request):
            def __init__(self, url, data=None, headers={},
                        origin_req_host=None, unverifiable=False, method=None):
                # Note:
                # urllib2.Request is OLD type class
                urllib2.Request.__init__(
                    self, url, data, headers, origin_req_host, unverifiable,
                )
                self.method = method
            def get_method(self):
                if self.method:
                    return self.method
                else:
                    return 'POST' if self.has_data() else 'GET'
        class HTTPRedirectHandler(urllib2.HTTPRedirectHandler):
            def redirect_request(self, req, fp, code, msg, headers, newurl):
                m = req.get_method()
                if (code in (301, 302, 303, 307) and m in ("GET", "HEAD")
                    or code in (301, 302, 303) and m == "POST"):
                    # Strictly (according to RFC 2616), 301 or 302 in response
                    # to a POST MUST NOT cause a redirection without confirmation
                    # from the user (of urllib2, in this case).  In practice,
                    # essentially all clients do redirect in this case, so we
                    # do the same.
                    # be conciliant with URIs containing a space
                    newurl = newurl.replace(' ', '%20')
                    newheaders = dict((k,v) for k,v in req.headers.items()
                                    if k.lower() not in ("content-length", "content-type")
                                    )
                    return Request(newurl,
                                headers=newheaders,
                                origin_req_host=req.get_origin_req_host(),
                                unverifiable=True,
                                method=m)
                else:
                    raise HTTPError(req.get_full_url(), code, msg, headers, fp)
        from urllib2 import (
            build_opener,
            HTTPPasswordMgrWithDefaultRealm,
            HTTPBasicAuthHandler,
            HTTPDigestAuthHandler,
            HTTPError, URLError,
        )

    def retry(tries=4, delay=2, backoff=2):
        def inner(f):
            @functools.wraps(f)
            def wrap(*args, **kwargs):
                ctries, cdelay = tries, delay
                while ctries > 1:
                    try:
                        return f(*args, **kwargs)
                    except URLError:
                        time.sleep(cdelay)
                        ctries -= 1
                        cdelay *= backoff
                return f(*args, **kwargs)
            return wrap
        return inner

    def build_request(request):
        if 'url' not in request:
            raise Exception('A required "url" field is missing from %s' % request)
        get = lambda x, request=request: request.get(x, r[x])
        r = {
            'method': 'GET',
            'data': None,
            'headers': {},
            'output_file': '',
            'timeout': 0,
            'username': '',
            'password': '',
            'max_redirect': 20,
            'retry': 1,
            'gzip_decompress': 0,
        }
        r.update({
            'url': request['url'],
            'method': get('method'),
            'data': get('data'),
            'headers': get('headers'),
            'output_file': get('output_file'),
            'timeout': int(get('timeout')),
            'username': get('username'),
            'password': get('password'),
            'max_redirect': int(get('max_redirect')),
            'retry': int(get('retry')),
            'gzip_decompress': bool(int(get('gzip_decompress'))),
        })
        r['data'] = r['data'].encode('utf-8') if r['data'] else None
        r['timeout'] = r['timeout'] if r['timeout'] else None
        return r

    def urlopen(request):
        request = build_request(request)
        rhandler = HTTPRedirectHandler()
        rhandler.max_redirections = request['max_redirect']
        opener = build_opener(rhandler)
        if request['username']:
            passmgr = HTTPPasswordMgrWithDefaultRealm()
            passmgr.add_password(
                None, request['url'],
                request['username'],
                request['password'],
            )
            opener.add_handler(HTTPBasicAuthHandler(passmgr))
            opener.add_handler(HTTPDigestAuthHandler(passmgr))
        req = Request(
            url=request['url'],
            data=request['data'],
            headers=request['headers'],
            method=request['method'],
        )
        if request['gzip_decompress']:
            req.add_header('Accept-encoding', 'gzip')
        try:
            res = retry(tries=request['retry'])(opener.open)(
                req, timeout=request['timeout']
            )
        except HTTPError as e:
            res = e
        if not hasattr(res, 'version'):
            # urllib2 does not have 'version' field
            import httplib
            res.version = httplib.HTTPConnection._http_vsn
        response_status = "HTTP/%s %d %s\n" % (
            '1.1' if res.version == 11 else '1.0',
            res.code, res.msg,
        )
        response_headers = str(res.headers)
        response_body = res.read()
        if (request['gzip_decompress']
                and res.headers.get('Content-Encoding') == 'gzip'):
            response_body = gzip_decompress(response_body)
        if hasattr(res.headers, 'get_content_charset'):
            # Python 3
            response_encoding = res.headers.get_content_charset()
        else:
            # Python 2
            response_encoding = res.headers.getparam('charset')
        if response_encoding:
            response_body = response_body.decode(response_encoding)
        return (
            request['url'],
            response_status + response_headers,
            response_body,
        )

    def format_exception():
        exc_type, exc_obj, tb = sys.exc_info()
        f = tb.tb_frame
        lineno = tb.tb_lineno
        filename = f.f_code.co_filename
        exception = "%s: %s at %s:%d" % (
            exc_obj.__class__.__name__,
            exc_obj, filename, lineno,
        )
        return exception

    return urlopen, format_exception

# NOTE:
# __name__ check cannot be used to check if the script is called from vim
try:
    import vim
    # Success. Assume it is executed from Vim
    _vital_vim_network_http_urlopen, _vital_vim_network_http_format_exception = \
            _vital_vim_network_http_define()
    try:
        _vital_vim_network_http_urlopen_result = \
                _vital_vim_network_http_urlopen(vim.eval("a:request"))
    except:
        _vital_vim_network_http_urlopen_result = \
                _vital_vim_network_http_format_exception()
except ImportError:
    # Fail. Assume it is executed as python script
    if __name__ == '__main__':
        import sys
        import ast

        urlopen, format_exception = _vital_vim_network_http_define()

        def urlopen_from_terminal(literal_request):
            request = ast.literal_eval(literal_request)
            try:
                url, headers, body = urlopen(request)
                print(url)
                for key, value in headers.items():
                    print('%s: %s' % (key, value))
                print(response_body)
                return 0
            except:
                exception = format_exception()
                print(exception)
                # NOTE:
                # exit status should follow curl's one?
                return 1

        def unittest():
            base = 'https://gist.githubusercontent.com/lambdalisue/'
            url1 = 'fc3da1ac9953df6f3a89/raw/test.txt'
            request = {
                'url': base + url1
            }
            url, headers, body = urlopen(request)
            assert url == base + url1
            assert body == 'test'

        # To support ancient python and modern python
        # do not use optparse/argparse
        if len(sys.argv) != 2:
            print('Usage: %s [-t/--unittest] [LITERAL_REQUEST]' % sys.argv[0])
            print('')
            print('LITERAL_REQUEST:')
            print('A literal vimson (like json with single quotes) which has')
            print('- url (str) : request url')
            print('- method (str) : request method')
            print('- data (str) : request data for POST')
            print('- headers (vimson) : header vimson')
            print('- output_file (str) : a name of output file')
            print('- timeout (int) : timeout in second [0]')
            print('- username (str) : a username used for auth')
            print('- password (str) : a password used for auth')
            print('- max_redirect (int) : a number of max redirection [20]')
            print('- retry (int) : a number of retry [1]')
            print('- gzip_decompress (bool:0/1) : decompress gzip or not')
            sys.exit(1)
        elif sys.argv[1] == '-t' or sys.argv[1] == '--unittest':
            unittest()
        else:
            sys.exit(urlopen_from_terminal(sys.argv[1]))
