# frozen_string_literal: true

require "minitest/autorun"
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

  def test_fails_a_skill_naming_an_internal_codename
    write_skill("logpacer", frontmatter("logpacer") + "The loganalyzer parses your logs.\n")

    output, status = run_script

    refute status.success?
    assert_includes output, "skills/logpacer/SKILL.md"
    assert_includes output, "loganalyzer"
  end

  def test_fails_every_denylisted_term
    [
      "sublogger", "Sublog", "loganalyzer", "LogRelay", "logpacer_wire", "OpenTelemetry-native",
      "edge.internal.logpacer.com", "app.internal", "registry.logpacer.com", "Harbor"
    ].each do |term|
      write_skill("logpacer", frontmatter("logpacer") + "Mentions #{term} here.\n")

      output, status = run_script

      refute status.success?, "expected #{term.inspect} to be rejected"
      assert_includes output, "skills/logpacer/SKILL.md", term
    end
  end

  def test_fails_a_denylisted_term_in_a_skill_reference
    write_file("skills/logpacer/references/node.md", "Send spans to logrelay.\n")

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
