Then /^the file "(.*?)" should contain JSON exactly like:$/ do |file, exact_content|
  json = IO.read(expand_path(file))
  JSON.parse(json).should == JSON.parse(exact_content)
end
