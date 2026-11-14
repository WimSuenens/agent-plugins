#!/bin/bash
# Slice #168 (contract 168-skill-frontmatter, sections 2 and 3): every plugins/*/skills/*/SKILL.md has frontmatter a strict YAML parser reads.
# Prints `frontmatter: FAIL <path> <message>` per bad file and `frontmatter: ok <n> files` on success. Needs ruby (Psych, stock on macOS).
# Targeted test: bash tests/factory/test_skill_frontmatter.sh
. "$(dirname "$0")/lib.sh"
FXD="$REPO/tests/factory/fixtures/frontmatter"

out="$(cd "$REPO" && ruby -ryaml -e '
files = Dir.glob("plugins/*/skills/*/SKILL.md").sort
if files.empty? then puts "frontmatter: FAIL (no files) no plugins/*/skills/*/SKILL.md found"; exit 1 end
bad = 0
files.each do |f|
  lines = File.read(f).lines
  fin = lines[0] && lines[0].chomp == "---" ? lines[1..-1].index { |l| l.chomp == "---" } : nil
  if fin.nil? then puts "frontmatter: FAIL #{f} no frontmatter block"; bad += 1; next end
  begin
    m = YAML.safe_load(lines[1, fin].join)
    raise "frontmatter is not a mapping" unless m.is_a?(Hash)
    raise "description is not a string" unless m["description"].is_a?(String)
    raise "name is not a string equal to the directory name (#{m["name"].inspect})" unless m["name"].is_a?(String) && m["name"] == File.basename(File.dirname(f))
  rescue Exception => e
    puts "frontmatter: FAIL #{f} #{e.message.gsub(/\s+/, " ")}"; bad += 1
  end
end
puts "frontmatter: ok #{files.size} files" if bad == 0
exit(bad == 0 ? 0 : 1)
' 2>&1)"
rc=$?
printf '%s\n' "$out"
ck frontmatter-all-skills-parse 0 "$rc"

# point 4 and 5: the two fixed files
for s in obeya run; do
  P="plugins/factory/skills/$s/SKILL.md"
  want="$(cat "$FXD/$s.description")"
  got="$(cd "$REPO" && ruby -ryaml -e 'l=File.read(ARGV[0]).lines; e=l[1..-1].index{|x|x.chomp=="---"}; print YAML.safe_load(l[1,e].join)["description"]' "$P" 2>/dev/null)"
  ck "$s-description-byte-equal-to-pre-slice-text" "$want" "$got"
  ck "$s-line3-key-and-value-on-one-line" 1 "$(sed -n 3p "$REPO/$P" | grep -c '^description: ')"
  if git -C "$REPO" rev-parse -q --verify origin/main >/dev/null 2>&1; then
    # the frontmatter apart from line 3 is unchanged (slice 0 of #207 edits the body of run/SKILL.md, so the body is no longer compared)
    fm() { awk 'NR==1 {print; next} {print} /^---$/ {exit}'; }
    ck "$s-other-frontmatter-lines-unchanged" "" "$(diff <(git -C "$REPO" show "origin/main:$P" | fm | sed 3d) <(fm < "$REPO/$P" | sed 3d))"
  else skip "$s-other-lines-unchanged" "origin/main not available"; fi
done
done_
