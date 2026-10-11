import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;

class PageContent {
  const PageContent({
    required this.title,
    required this.description,
    required this.text,
  });
  final String title;
  final String description;
  final String text;

  String get summary =>
      'Title: $title\nDescription: $description\nContent:\n$text';
}

const _maxText = 6000;

/// Pulls title, meta description and visible text out of an HTML document.
PageContent extractPage(String source) {
  final doc = html.parse(source);
  for (final el in doc.querySelectorAll(
    'script,style,noscript,svg,nav,footer',
  )) {
    el.remove();
  }
  final title = doc.querySelector('title')?.text.trim() ?? '';
  final desc =
      doc
          .querySelector('meta[name="description"]')
          ?.attributes['content']
          ?.trim() ??
      doc
          .querySelector('meta[property="og:description"]')
          ?.attributes['content']
          ?.trim() ??
      '';
  var text = (doc.body?.text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.length > _maxText) text = text.substring(0, _maxText);
  return PageContent(title: title, description: desc, text: text);
}

class FetchException implements Exception {
  FetchException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Fetches a page. On web, many sites block this via CORS; callers treat
/// failures as inconclusive rather than as a bad proof.
Future<PageContent> fetchPage(Dio dio, Uri url) async {
  try {
    final res = await dio.getUri<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        maxRedirects: 4,
      ),
    );
    final page = extractPage(res.data ?? '');
    if (page.text.isEmpty && page.title.isEmpty) {
      throw FetchException(
        'The page had no readable text (probably needs JavaScript or a login).',
      );
    }
    return page;
  } on DioException catch (e) {
    final code = e.response?.statusCode;
    throw FetchException(
      code != null
          ? 'The page answered HTTP $code.'
          : 'Could not reach the page (blocked, offline or private).',
    );
  }
}
