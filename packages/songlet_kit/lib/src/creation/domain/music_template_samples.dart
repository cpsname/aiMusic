/// Short sample clips of the create-home templates (docs/ui P01 play buttons),
/// served by `GET /v1/templates` `templates[]` (contract extension, ADR-0008) and
/// cached on the device after the first play. The current server no longer sends
/// `templates[]` (the clips are the `preview_audio_url` of the inspiration with
/// the template's id, ADR-0029); this source serves older ones.
abstract interface class MusicTemplateSampleSource {
  /// Local path of [templateId]'s sample, downloading it on first use.
  /// Throws when the server offers no sample for it.
  Future<String> samplePath(String templateId);
}
