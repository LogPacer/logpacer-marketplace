# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "json"
require "open3"
require "tmpdir"

class SyncVersionsTest < Minitest::Test
  SCRIPT = File.expand_path("../scripts/sync-versions", __dir__)

  PLUGIN_MANIFESTS = %w[
    .claude-plugin/plugin.json
    .codex-plugin/plugin.json
    .cursor-plugin/plugin.json
    plugin.json
    gemini-extension.json
  ].freeze

  MARKETPLACES = %w[
    .claude-plugin/marketplace.json
    .cursor-plugin/marketplace.json
  ].freeze

  def setup
    @root = Dir.mktmpdir("sync-versions")
    FileUtils.mkdir_p(File.join(@root, "scripts"))
    FileUtils.cp(SCRIPT, File.join(@root, "scripts", "sync-versions"))
    PLUGIN_MANIFESTS.each { |path| write_json(path, { "name" => "logpacer", "version" => "1.2.3" }) }
    MARKETPLACES.each do |path|
      write_json(path, { "name" => "logpacer", "plugins" => [{ "name" => "logpacer", "source" => "./", "version" => "1.2.3" }] })
    end
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_check_passes_when_every_manifest_matches
    output, status = run_script("--check")

    assert status.success?, output
  end

  def test_check_fails_when_a_plugin_manifest_differs
    write_json(".codex-plugin/plugin.json", { "name" => "logpacer", "version" => "1.2.4" })

    output, status = run_script("--check")

    refute status.success?
    assert_includes output, ".codex-plugin/plugin.json"
    assert_includes output, "1.2.4"
  end

  def test_check_fails_when_a_marketplace_entry_differs
    write_json(".cursor-plugin/marketplace.json", { "name" => "logpacer", "plugins" => [{ "name" => "logpacer", "source" => "./", "version" => "0.9.0" }] })

    output, status = run_script("--check")

    refute status.success?
    assert_includes output, ".cursor-plugin/marketplace.json"
  end

  def test_check_fails_when_a_manifest_has_no_version
    write_json("gemini-extension.json", { "name" => "logpacer" })

    output, status = run_script("--check")

    refute status.success?
    assert_includes output, "gemini-extension.json"
  end

  def test_fix_rewrites_drifted_versions_from_the_claude_manifest
    write_json("plugin.json", { "name" => "logpacer", "version" => "0.0.1" })
    write_json(".claude-plugin/marketplace.json", { "name" => "logpacer", "plugins" => [{ "name" => "logpacer", "source" => "./", "version" => "0.0.1" }] })

    output, status = run_script("--fix")

    assert status.success?, output
    assert_equal "1.2.3", read_json("plugin.json")["version"]
    assert_equal "1.2.3", read_json(".claude-plugin/marketplace.json")["plugins"].first["version"]
    assert run_script("--check").last.success?
  end

  private
    def run_script(*args)
      Open3.capture2e("ruby", File.join(@root, "scripts", "sync-versions"), *args)
    end

    def write_json(path, data)
      full = File.join(@root, path)
      FileUtils.mkdir_p(File.dirname(full))
      File.write(full, JSON.pretty_generate(data) + "\n")
    end

    def read_json(path)
      JSON.parse(File.read(File.join(@root, path)))
    end
end
