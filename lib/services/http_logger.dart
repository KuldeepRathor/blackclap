import 'dart:convert';
import 'dart:developer' as developer;

class HttpLogger {
  static String generateCurl(String method, Uri uri, {Map<String, String>? headers, dynamic body}) {
    final buffer = StringBuffer();
    buffer.write('curl --request $method \'$uri\'');
    
    headers?.forEach((key, value) {
      buffer.write(' \\\n  --header \'$key: $value\'');
    });

    if (body != null) {
      if (body is List<int>) {
        // Skip adding large binary payloads to Curl directly
        buffer.write(' \\\n  --data-binary \'[Binary Data: ${body.length} bytes]\'');
      } else if (body is Map || body is List) {
        try {
          final data = json.encode(body);
          buffer.write(' \\\n  --data \'$data\'');
        } catch (_) {
          buffer.write(' \\\n  --data \'$body\'');
        }
      } else {
        buffer.write(' \\\n  --data \'$body\'');
      }
    }

    return buffer.toString();
  }

  static void logRequest(String method, Uri uri, {Map<String, String>? headers, dynamic body}) {
    final curl = generateCurl(method, uri, headers: headers, body: body);
    developer.log('┌🚀------------------ REQUEST ------------------', name: 'HTTP');
    developer.log('| URL: $method $uri', name: 'HTTP');
    if (headers != null && headers.isNotEmpty) {
      developer.log('| Headers:', name: 'HTTP');
      headers.forEach((k, v) => developer.log('|   $k: $v', name: 'HTTP'));
    }
    if (body != null) {
      developer.log('| Body:', name: 'HTTP');
      if (body is List<int>) {
        developer.log('|   [Raw binary payload: ${body.length} bytes]', name: 'HTTP');
      } else {
        developer.log('|   $body', name: 'HTTP');
      }
    }
    developer.log('| cURL command:', name: 'HTTP');
    curl.split('\n').forEach((line) => developer.log('|   $line', name: 'HTTP'));
    developer.log('└🚀---------------------------------------------', name: 'HTTP');
  }

  static void logResponse(int statusCode, String method, Uri uri, {Map<String, String>? headers, String? body, Duration? duration}) {
    developer.log('┌✅------------------ RESPONSE [$statusCode] ------------------', name: 'HTTP');
    developer.log('| URL: $method $uri', name: 'HTTP');
    if (duration != null) {
      developer.log('| Duration: ${duration.inMilliseconds}ms', name: 'HTTP');
    }
    if (headers != null && headers.isNotEmpty) {
      developer.log('| Headers:', name: 'HTTP');
      headers.forEach((k, v) => developer.log('|   $k: $v', name: 'HTTP'));
    }
    if (body != null && body.isNotEmpty) {
      developer.log('| Body:', name: 'HTTP');
      try {
        final parsed = json.decode(body);
        final prettyString = const JsonEncoder.withIndent('  ').convert(parsed);
        prettyString.split('\n').forEach((line) => developer.log('|   $line', name: 'HTTP'));
      } catch (_) {
        body.split('\n').forEach((line) => developer.log('|   $line', name: 'HTTP'));
      }
    }
    developer.log('└✅------------------------------------------------------------', name: 'HTTP');
  }

  static void logError(String method, Uri uri, dynamic error, {int? statusCode, String? responseBody}) {
    developer.log('┌❌------------------ ERROR ------------------', name: 'HTTP');
    developer.log('| URL: $method $uri', name: 'HTTP');
    if (statusCode != null) {
      developer.log('| Status Code: $statusCode', name: 'HTTP');
    }
    developer.log('| Error: $error', name: 'HTTP');
    if (responseBody != null && responseBody.isNotEmpty) {
      developer.log('| Response Body:', name: 'HTTP');
      try {
        final parsed = json.decode(responseBody);
        final prettyString = const JsonEncoder.withIndent('  ').convert(parsed);
        prettyString.split('\n').forEach((line) => developer.log('|   $line', name: 'HTTP'));
      } catch (_) {
        responseBody.split('\n').forEach((line) => developer.log('|   $line', name: 'HTTP'));
      }
    }
    developer.log('└❌-------------------------------------------', name: 'HTTP');
  }
}
