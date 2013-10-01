//
//  YACConnectionLog.m
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

#import "YACConnectionLog.h"
#import "YACLogEvent.h"

@interface YACConnectionLog () <NSURLConnectionDelegate>
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSMutableData *mutableResponseBody;
@property (nonatomic, strong) NSMutableArray *mutableEvents;
@property (nonatomic, copy) NSString *UUID;
@end

@implementation YACConnectionLog

- (id)initWithRequest:(NSURLRequest *)request
{
    self = [super init];
    if (self) {
        _request = request;
        _mutableEvents = [NSMutableArray array];
    }
    return self;
}

- (void)log:(NSString *)message
{
    [self logFormat:@"%@", message];
}

- (void)logFormat:(NSString *)format, ...
{
	va_list args;
	if (format) {
		va_start(args, format);

        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        YACLogEvent *event = [YACLogEvent eventWithMessage:message];
        [self.mutableEvents addObject:event];

        va_end(args);
    }
}

- (void)log_startLoading
{
    [self log:@"Start loading."];
}

- (void)log_stopLoading
{
    [self log:@"Stop loading."];
}

- (void)log_didReceiveData:(NSData *)data
{
    if (self.mutableResponseBody == nil) {
        self.mutableResponseBody = [NSMutableData data];
    }
    [self.mutableResponseBody appendData:data];
    [self logFormat:@"Did receive data (%d bytes).", [data length]];
}

- (void)log_didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
    [self log:@"Did receive response."];
}

- (void)log_willSendRequest:(NSURLRequest *)request
{
    [self log:@"Will send request."];
}

- (void)log_wasRedirectedToRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    self.response = response;
    [self log:@"Did receive redirect response."];
}

- (void)log_didFinishLoading
{
    [self log:@"Did finish loading."];
}

- (void)log_didFailWithError:(NSError *)error
{
    [self logFormat:@"Did fail with error.\nError: %@", error];
}

- (void)log_didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [self logFormat:@"Did cancel authentication challenge: %@", challenge];
}

- (void)log_didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [self logFormat:@"Did receive authentication challenge: %@", challenge];
}

#pragma mark - Properties

- (NSArray *)events
{
    return [NSArray arrayWithArray:self.mutableEvents];
}

- (NSMutableData *)mutableResponseBody
{
    if (_mutableResponseBody == nil) {
        _mutableResponseBody = [NSMutableData data];
    }
    return _mutableResponseBody;
}

- (NSData *)responseBody
{
    return [self.mutableResponseBody copy];
}

- (NSString *)UUID
{
    if (_UUID == nil) {
        _UUID = [[NSUUID UUID] UUIDString];
    }
    return _UUID;
}

@end
