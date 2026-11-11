import Foundation
import FoundationModels

/// On-device prompt polishing with Apple's SystemLanguageModel (PRD §6.2, §7.1):
/// turns the user's name + keywords into one vivid sentence in the target
/// lyric language and drops artist / band / song names ("in the style of …")
/// before anything reaches the backend. Free, private, offline.
///
/// Best effort by design: when the model is unavailable (device not eligible,
/// Apple Intelligence off, model still downloading, unsupported locale) or the
/// request trips the model's guardrails, the raw text is returned unchanged —
/// the backend assembles the real prompt anyway, and the client-side preflight
/// has already blocked artist names.
final class PromptPolisher {
  func polish(raw: String, locale: String) async -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return raw }

    let model = SystemLanguageModel.default
    guard case .available = model.availability else {
      NSLog("[PromptPolisher] SystemLanguageModel unavailable: %@", String(describing: model.availability))
      return raw
    }
    let language = Locale(identifier: locale)
    guard model.supportsLocale(language) else {
      NSLog("[PromptPolisher] locale %@ not supported by SystemLanguageModel", locale)
      return raw
    }

    let languageName = Locale(identifier: "en").localizedString(forIdentifier: locale) ?? locale
    let instructions = """
      You polish short briefs for a personal song. Rewrite the brief as ONE vivid \
      sentence of at most 200 characters, written in \(languageName). Keep the \
      recipient's name and every keyword. Remove any names of real singers, bands, \
      songs or albums and any phrase like "in the style of", "sound like" or "voice of". \
      Do not add quotes, emojis, hashtags or explanations. Output only the sentence.
      """
    do {
      let session = LanguageModelSession(model: model, instructions: instructions)
      let response = try await session.respond(
        to: trimmed,
        options: GenerationOptions(temperature: 0.3, maximumResponseTokens: 120))
      let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
      return text.isEmpty ? raw : String(text.prefix(240))
    } catch {
      NSLog("[PromptPolisher] generation failed: %@", String(describing: error))
      return raw
    }
  }
}
