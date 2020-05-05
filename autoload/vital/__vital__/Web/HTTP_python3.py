try:
    class DummyClassForLocalScope:
        def main():
            try:
                from StringIO import StringIO
            except ImportError:
                from io import StringIO
            import vim, urllib.request, urllib.error, socket, gzip

            responses = vim.bindeval('responses')

            class CustomHTTPRedirectHandler(urllib.request.HTTPRedirectHandler):
                def __init__(self, max_redirect):
                    self.max_redirect = max_redirect

                def redirect_request(self, req, fp, code, msg, headers, newurl):
                    if self.max_redirect == 0:
                        return None
                    if 0 < self.max_redirect:
                        self.max_redirect -= 1
                    header_list = list(filter(None, str(headers).split("\r\n")))
                    responses.extend([[[status(code, msg)] + header_list, fp.read()]])
                    return urllib.request.HTTPRedirectHandler.redirect_request(self, req, fp, code, msg, headers, newurl)

            def vimlist2str(list):
                if not list:
                    return None
                return "\n".join([s.replace("\n", "\0") for s in list])

            def status(code, msg):
                return "HTTP/1.0 %d %s\r\n" % (code, msg)

            def access():
                settings = vim.eval('a:settings')
                data = vimlist2str(settings.get('data'))
                timeout = settings.get('timeout')
                if timeout:
                    timeout = float(timeout)
                request_headers = settings.get('headers')
                max_redirect = int(settings.get('maxRedirect'))
                director = urllib.request.build_opener(CustomHTTPRedirectHandler(max_redirect))
                if 'username' in settings:
                    passman = urllib.request.HTTPPasswordMgrWithDefaultRealm()
                    passman.add_password(
                        None,
                        settings['url'],
                        settings['username'],
                        settings.get('password', ''))
                    basicauth = urllib.request.HTTPBasicAuthHandler(passman)
                    digestauth = urllib.request.HTTPDigestAuthHandler(passman)
                    director.add_handler(basicauth)
                    director.add_handler(digestauth)
                if 'bearerToken' in settings:
                    request_headers.setdefault('Authorization', 'Bearer ' + settings['bearerToken'])
                req = urllib.request.Request(settings['url'], data, request_headers)
                req.get_method = lambda: settings['method']
                default_timeout = socket.getdefaulttimeout()
                try:
                    # for Python 2.5 or before <- Is this needed?
                    socket.setdefaulttimeout(timeout)
                    res = director.open(req, timeout=timeout)
                except urllib.error.HTTPError as res:
                    pass
                except urllib.error.URLError:
                    return ('', '')
                except socket.timeout:
                    return ('', '')
                finally:
                    socket.setdefaulttimeout(default_timeout)

                st = status(res.code, res.msg)
                response_headers = st + ''.join(res.headers)
                response_body = res.read()

                gzip_decompress = settings.get('gzipDecompress', False)
                if gzip_decompress:
                    buf = StringIO(response_body)
                    f = gzip.GzipFile(fileobj=buf)
                    response_body = f.read()[:-1]

                return (response_headers, response_body)

            (header, body) = access()
            responses.extend([[header.split("\r\n"), body]])

        main()
        raise RuntimeError("Exit from local scope")

except RuntimeError as exception:
    if exception.args != ("Exit from local scope",):
        raise exception
