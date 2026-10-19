# frozen_string_literal: true

require "minitest/autorun"
require "digest"
require "fileutils"
require "open3"
require "tmpdir"

class CheckSkillsTest < Minitest::Test
  SCRIPT = File.expand_path("../scripts/check-skills", __dir__)

  def setup
    @root = Dir.mktmpdir("check-skills")
    FileUtils.mkdir_p(File.join(@root, "scripts"))
    FileUtils.cp(SCRIPT, File.join(@root, "scripts", "check-skills"))
    write_skill("logpacer", frontmatter("logpacer") + "Connect to LogPacer and follow the live guide.\n")
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_passes_a_valid_skill
    output, status = run_script

    assert status.success?, output
  end

  def test_fails_a_skill_over_8000_bytes
    body = frontmatter("logpacer")
    write_skill("logpacer", body + ("a" * (9000 - body.bytesize)))

    output, status = run_script

    refute status.success?
    assert_includes output, "skills/logpacer/SKILL.md"
    assert_includes output, "9000 bytes"
  end

  # The shipped list holds only digests, so these tests deny a made-up
  # codename in the copied script rather than name a real one here.
  def test_fails_a_skill_naming_an_internal_codename_in_any_case
    deny_codename("frobnicator")

    ["The frobnicator parses your logs.\n", "Ask Frobnicator.\n", "Run frobnicator-rs.\n"].each do |body|
      write_skill("logpacer", frontmatter("logpacer") + body)

      output, status = run_script

      refute status.success?, "expected #{body.inspect} to be rejected"
      assert_includes output, "skills/logpacer/SKILL.md"
      assert_includes output, "internal codename"
    end
  end

  def test_ships_codenames_only_as_sha256_digests
    script = File.read(SCRIPT)
    digests = script[/CODENAME_DIGESTS = %w\[(.*?)\]/m, 1].split

    refute_empty digests
    assert digests.all? { |digest| digest.match?(/\A\h{64}\z/) }, "every entry is a SHA-256 hex digest"
  end

  def test_fails_internal_and_unlisted_logpacer_hosts
    ["metrics.example.internal", "db.internal", "beta.logpacer.com", "https://staging.logpacer.com/mcp"].each do |host|
      write_skill("logpacer", frontmatter("logpacer") + "Mentions #{host} here.\n")

      output, status = run_script

      refute status.success?, "expected #{host.inspect} to be rejected"
      assert_includes output, "skills/logpacer/SKILL.md", host
    end
  end

  def test_passes_public_hosts_and_the_docker_host
    write_skill("logpacer", frontmatter("logpacer") +
      "Connect to https://app.logpacer.com/mcp (see logpacer.com), and from a container reach host.docker.internal:4318.\n")

    output, status = run_script

    assert status.success?, output
  end

  def test_fails_opentelemetry_native_in_a_skill_reference
    write_file("skills/logpacer/references/node.md", "LogPacer is OpenTelemetry-native.\n")

    output, status = run_script

    refute status.success?
    assert_includes output, "skills/logpacer/references/node.md"
  end

  def test_fails_a_name_that_does_not_match_the_directory
    write_skill("logpacer", frontmatter("logpacer-start") + "Body.\n")

    output, status = run_script

    refute status.success?
    assert_includes output, "logpacer-start"
  end

  def test_fails_a_skill_without_a_description
    write_skill("logpacer", "---\nname: logpacer\n---\n\nBody.\n")

    output, status = run_script

    refute status.success?
    assert_includes output, "description"
  end

  def test_fails_a_skill_without_frontmatter
    write_skill("logpacer", "# LogPacer\n\nBody.\n")

    output, status = run_script

    refute status.success?
    assert_includes output, "frontmatter"
  end

  def test_fails_a_frontmatter_key_outside_the_agent_skills_set
    write_skill("logpacer", "---\nname: logpacer\ndescription: Start here.\ndisable-model-invocation: true\n---\n\nBody.\n")

    output, status = run_script

    refute status.success?
    assert_includes output, "disable-model-invocation"
  end

  private
    def run_script
      Open3.capture2e("ruby", File.join(@root, "scripts", "check-skills"))
    end

    def deny_codename(word)
      path = File.join(@root, "scripts", "check-skills")
      File.write(path, File.read(path).sub("CODENAME_DIGESTS = %w[", "CODENAME_DIGESTS = %w[\n  #{Digest::SHA256.hexdigest(word)}"))
    end

    def frontmatter(name)
      "---\nname: #{name}\ndescription: Start here for LogPacer.\n---\n\n"
    end

    def write_skill(directory, content)
      write_file("skills/#{directory}/SKILL.md", content)
    end

    def write_file(path, content)
      full = File.join(@root, path)
      FileUtils.mkdir_p(File.dirname(full))
      File.write(full, content)
    end
end
