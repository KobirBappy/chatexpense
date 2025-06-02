// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class OpenAIService {
//   static const _apiKey = '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';

//   static Future<String> categorize(String description) async {
//     final url = Uri.parse('https://api.openai.com/v1/chat/completions');
//     final response = await http.post(
//       url,
//       headers: {
//         'Authorization': 'Bearer $_apiKey',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         "model": "gpt-3.5-turbo",
//         "messages": [
//           {
//             "role": "system",
//             "content": "You are a helpful assistant that categorizes expenses into categories like Food, Transportation, Household, Entertainment, etc."
//           },
//           {
//             "role": "user",
//             "content": "Categorize this expense: $description"
//           }
//         ]
//       }),
//     );

//     final data = jsonDecode(response.body);
//     return data['choices'][0]['message']['content'];
//   }
// }
