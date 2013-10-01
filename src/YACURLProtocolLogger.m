//
//  YACURLProtocolLogger.m
//
//  Copyright (c) 2013 Alexey Dodonov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "YACURLProtocolLogger.h"
#import "YACConnectionLog.h"
#import "YACHTTPServer.h"

#define ENABLE_LOGGER

NSString * const YACURLProtocolLoggerRequestMarker = @"YACURLProtocolLoggerRequestMarker";

@interface YACURLProtocolLogger () <NSURLConnectionDelegate>
@property (strong) YACConnectionLog *logger;
@property (strong) NSURLConnection *connection;
@end

@implementation YACURLProtocolLogger

#ifdef ENABLE_LOGGER
+ (void)load
{
    if (self == [YACURLProtocolLogger class]) {
        [self registerClass:self];
    }
}
#endif

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([request.URL.absoluteString hasPrefix:@"data:"]) {
        return NO;
    }

    id marker = [NSURLProtocol propertyForKey:YACURLProtocolLoggerRequestMarker
                                    inRequest:request];
    return (marker == nil);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (id)initWithRequest:(NSURLRequest *)request
       cachedResponse:(NSCachedURLResponse *)cachedResponse
               client:(id<NSURLProtocolClient>)client
{
    self = [super initWithRequest:request
                   cachedResponse:cachedResponse
                           client:client];
    if (self) {

        NSMutableURLRequest *mURLRequest = [request mutableCopy];
        [NSURLProtocol setProperty:YACURLProtocolLoggerRequestMarker
                            forKey:YACURLProtocolLoggerRequestMarker
                         inRequest:mURLRequest];

        _connection = [[NSURLConnection alloc] initWithRequest:[mURLRequest copy]
                                                          delegate:self startImmediately:NO];

        _logger = [[YACConnectionLog alloc] initWithRequest:request];
        [[YACHTTPServer sharedServer] addConnectionLog:_logger];

    }
    return self;
}

- (void)startLoading
{
    [self.logger log_startLoading];
    [self.connection start];
}

- (void)stopLoading
{
    [self.logger log_stopLoading];
    [self.connection cancel];
}

#pragma mark - NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.logger log_didReceiveData:data];
    [[self client] URLProtocol:self didLoadData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.logger log_didReceiveResponse:response];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    if (redirectResponse == nil) {
        [self.logger log_willSendRequest:request];
    }
    else {
        [self.logger log_wasRedirectedToRequest:request redirectResponse:redirectResponse];
        [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:redirectResponse];
    }
    return request;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.logger log_didFinishLoading];
    [[self client] URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.logger log_didFailWithError:error];
    [[self client] URLProtocol:self didFailWithError:error];
}

#pragma mark Connection Authentication

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [self.logger log_didCancelAuthenticationChallenge:challenge];
    [[self client] URLProtocol:self didCancelAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [self.logger log_didReceiveAuthenticationChallenge:challenge];
    [[self client] URLProtocol:self didReceiveAuthenticationChallenge:challenge];
}

@end
