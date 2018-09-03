require 'spec_helper'
require 'rspec_api_documentation/dsl'
require 'net/http'

describe "Non-api documentation specs" do
  it "should not be polluted by the rspec api dsl" do |example|
    expect(example.example_group).to_not include(RspecApiDocumentation::DSL)
  end
end

resource "Order" do
  describe "example metadata" do
    subject { |example| example.metadata }

    its([:resource_name]) { should eq("Order") }
    its([:document]) { should be_truthy }
  end

  describe "example context" do
    it "should provide a client" do
      client.should be_a(RspecApiDocumentation::RackTestClient)
    end

    it "should return the same client every time" do
      client.should equal(client)
    end
  end

  [:post, :get, :put, :delete, :head, :patch].each do |http_method|
    send(http_method, "/path") do
      specify {|example| example.example_group.description.should eq("#{http_method.to_s.upcase} /path") }

      describe "example metadata" do
        subject {|example| example.metadata }

        its([:method]) { should eq(http_method) }
        its([:route]) { should eq("/path") }
      end

      describe "example context" do
        subject { self }
        let(:example) { |example| example }

        its(:method) { should eq(http_method) }
        its(:path) { should eq("/path") }

        describe "do_request" do
          it "should call the correct method on the client" do
            client.should_receive(http_method)
            do_request
          end
        end
      end
    end
  end

  context "required_parameters" do
    parameter :type, "The type of drink you want."
    parameter :size, "The size of drink you want."
    parameter :note, "Any additional notes about your order."

    subject { |example| example.metadata }

    post "/orders" do
      required_parameters :type, :size

      it "should have type and size required" do
        subject[:parameters].should eq(
          [
            { :name => "type", :description => "The type of drink you want.", :required => true },
            { :name => "size", :description => "The size of drink you want.", :required => true },
            { :name => "note", :description => "Any additional notes about your order." }
          ]
        )
      end
    end

    get "/orders" do
      it "should not have type and size required" do
        subject[:parameters].should eq(
          [
            { :name => "type", :description => "The type of drink you want." },
            { :name => "size", :description => "The size of drink you want." },
            { :name => "note", :description => "Any additional notes about your order." }
          ]
        )
      end
    end
  end

  post "/orders" do
    parameter :type, "The type of drink you want."
    parameter :size, "The size of drink you want."
    parameter :note, "Any additional notes about your order."

    required_parameters :type, :size

    let(:type) { "coffee" }
    let(:size) { "medium" }

    describe "example metadata" do
      subject { |example| example.metadata }

      it "should include the documentated parameters" do
        subject[:parameters].should eq(
          [
            { :name => "type", :description => "The type of drink you want.", :required => true },
            { :name => "size", :description => "The size of drink you want.", :required => true },
            { :name => "note", :description => "Any additional notes about your order." }
          ]
        )
      end
    end

    describe "example context" do
      subject { self }

      describe "params" do
        let(:example) { |example| example }

        it "should equal the assigned parameter values" do
          params.should eq("type" => "coffee", "size" => "medium")
        end
      end
    end
  end

  put "/orders/:id" do
    parameter :type, "The type of drink you want."
    parameter :size, "The size of drink you want."
    parameter :note, "Any additional notes about your order."

    required_parameters :type, :size

    let(:type) { "coffee" }
    let(:size) { "medium" }

    let(:id) { 1 }

    describe "do_request" do
      let(:example) { |example| example }

      context "when raw_post is defined" do
        let(:raw_post) { { :bill => params }.to_json }

        it "should send the raw post body" do
          client.should_receive(method).with(path, raw_post, nil)
          do_request
        end
      end

      context "when raw_post is not defined" do
        it "should send the params hash" do
          client.should_receive(method).with(path, params, nil)
          do_request
        end
      end

      it "should allow extra parameters to be passed in" do
        client.should_receive(method).with(path, params.merge("extra" => true), nil)
        do_request(:extra => true)
      end

      it "should overwrite parameters" do
        client.should_receive(method).with(path, params.merge("size" => "large"), nil)
        do_request(:size => "large")
      end

      it "should overwrite path variables" do
        client.should_receive(method).with("/orders/2", params, nil)
        do_request(:id => 2)
      end
    end

    describe "no_doc" do
      let(:example) {|example| example}

      it "should not add requests" do 
        example.metadata[:requests] = ["first request"]

        no_doc do
          example.metadata[:requests].should be_empty
          example.metadata[:requests] = ["not documented"]
        end

        example.metadata[:requests].should == ["first request"]
      end
    end
  end

  get "/orders/:order_id/line_items/:id" do
    parameter :type, "The type document you want"

    describe "do_request" do
      let(:example) { |example| example }

      it "should correctly set path variables and other parameters" do
        client.should_receive(method).with("/orders/3/line_items/2?type=short", nil, nil)
        do_request(:id => 2, :order_id => 3, :type => 'short')
      end
    end
  end

  get "/orders/:order_id" do
    let(:order) { instance_double("order", id: 1) }

    describe "path" do
      let(:example) {|example| example}
      subject { self.path }

      context "when id has been defined" do
        let(:order_id) { order.id }

        it "should have the value of id subtituted for :id" do
          subject.should eq("/orders/1")
        end
      end

      context "when id has not been defined" do
        it "should be unchanged" do
          subject.should eq("/orders/:order_id")
        end
      end
    end
  end

  describe "nested parameters" do
    parameter :per_page, "Number of results on a page"

    it "should only have 1 parameter" do |example|
      example.metadata[:parameters].length.should == 1
    end

    context "another parameter" do
      parameter :page, "Current page"

      it 'should have 2 parameters' do |example|
        example.metadata[:parameters].length.should == 2
      end
    end
  end

  callback "Order creation notification callback" do
    it "should provide a destination" do
      destination.should be_a(RspecApiDocumentation::TestServer)
    end

    it "should return the same destination every time" do
      destination.should equal(destination)
    end

    describe "trigger_callback" do
      let(:callback_url) { "http://www.example.net/callback" }
      let(:callbacks_triggered) { [] }

      trigger_callback do
        callbacks_triggered << nil
      end

      it "should get called once when do_callback is called" do
        do_callback
        callbacks_triggered.length.should eq(1)
      end
    end

    describe "do_callback" do
      trigger_callback do
        uri = URI.parse(callback_url)
        Net::HTTP.start(uri.host, uri.port) do |http|
          http.request Net::HTTP::Post.new(uri.path)
        end
      end

      context "when callback_url is defined" do
        let(:callback_url) { "http://www.example.net/callback" }

        it "should mock requests to the callback url to be handled by the destination" do
          called = false
          expect(destination).to receive(:call) do
            called = true
            [200, {}, []]
          end
          do_callback
          called.should be true
        end
      end

      context "when callback_url is not defined" do
        it "should raise an exception" do
          expect { do_callback }.to raise_error("You must define callback_url")
        end
      end
    end

    describe "post vs get data" do
      parameter :id, "User id"
      parameter :page, "Page to list"
      parameter :message, "Message on the order"

      let(:message) { "Thank you" }
      let(:page) { 2 }
      let(:id) { 1 }

      get "/users/:id/orders" do
        let(:example) { |example| example }

        example "Page should be in the query string" do
          client.should_receive(method) do |path, data, headers|
            path.should =~ /^\/users\/1\/orders\?/
            path.split("?")[1].split("&").sort.should == "page=2&message=Thank+you".split("&").sort
            data.should be_nil
            headers.should be_nil
          end
          do_request
        end
      end

      post "/users/:id/orders" do
        let(:example) { |example| example }

        example "Page should be in the post body" do
          client.should_receive(method).with("/users/1/orders", {"page" => 2, "message" => "Thank you"}, nil)
          do_request
        end
      end
    end
  end

  context "#app" do
    it "should provide access to the configurations app" do
      app.should == RspecApiDocumentation.configuration.app
    end

    context "defining a new app, in an example" do
      let(:app) { "Sinatra" }

      it "should use the user defined app" do
        app.should == "Sinatra"
      end
    end
  end

  context "#scope_parameters" do
    post "/orders" do
      let(:api_key) { "1234" }
      let(:name) { "Order 5" }
      let(:size) { 5 }

      context "parameters except scope" do
        parameter :type, "Order type", :scope => :order

        it "should save the scope" do |example|
          param = example.metadata[:parameters].detect { |param| param[:name] == "type" }
          param[:scope].should == :order
        end
      end

      context "certain parameters" do
        parameter :api_key, "API Key"
        parameter :name, "Order name"
        parameter :size, "Size of order"

        scope_parameters :order, [:name, :size]
        let(:example) { |example| example }

        it 'should set the scope on listed parameters' do
          param = example.metadata[:parameters].detect { |param| param[:name] == "name" }
          param[:scope].should == :order
        end

        it 'parameters should be scoped appropriately' do
          params.should == { "api_key" => api_key, "order" => { "name" => name, "size" => size } }
        end
      end

      context "all parameters" do
        parameter :api_key, "API Key"
        parameter :name, "Order name"
        parameter :size, "Size of order"

        scope_parameters :order, :all
        let(:example) { |example| example }

        it "should scope all parameters under order" do
          params.should == { "order" => { "api_key" => api_key, "name" => name, "size" => size } }
        end
      end

      context "param does not exist" do
        it "should not raise exceptions" do
          expect {
            self.class.scope_parameters :order, [:not_there]
            self.class.scope_parameters :order, :all
          }.to_not raise_error
        end
      end
    end
  end

  context "#explanation" do
    post "/orders" do
      let(:example) { |example| example }

      it "Creating an order" do
        explanation "By creating an order..."
        example.metadata[:explanation].should == "By creating an order..."
      end
    end
  end

  context "proper query_string serialization" do
    get "/orders" do
      let(:example) { |example| example }

      context "with an array parameter" do
        parameter :id_eq, "List of IDs"

        let(:id_eq) { [1, 2] }

        example "parsed properly" do
          client.should_receive(:get) do |path, data, headers|
            Rack::Utils.parse_nested_query(path.gsub('/orders?', '')).should eq({"id_eq"=>['1', '2']})
          end
          do_request
        end
      end

      context "with a deep nested parameter, including Hashes and Arrays" do
        parameter :within_id, "Fancy search condition"

        let(:within_id) { {"first" => 1, "last" => 10, "exclude" => [3,5,7]} }
        scope_parameters :search, :all

        example "parsed properly" do
          client.should_receive(:get) do |path, data, headers|
            Rack::Utils.parse_nested_query(path.gsub('/orders?', '')).should eq({
              "search" => { "within_id" => {"first" => '1', "last" => '10', "exclude" => ['3','5','7']}}
            })
          end
          do_request
        end
      end
    end
  end



  context "auto request" do
    let(:example) { |example| example }

    post "/orders" do
      parameter :order_type, "Type of order"

      context "no extra params" do
        before do
          client.should_receive(:post).with("/orders", {}, nil)
        end

        example_request "Creating an order"

        example_request "should take a block" do
          params
        end
      end

      context "extra options for do_request" do
        before do
          client.should_receive(:post).with("/orders", {"order_type" => "big"}, nil)
        end

        example_request "should take an optional parameter hash", :order_type => "big"
      end
    end
  end

  context "last_response helpers" do
    put "/orders" do
      let(:example) { |example| example }

      it "status" do
        allow(client).to receive(:last_response).and_return(double(:status => 200))
        status.should == 200
      end

      it "response_body" do
        allow(client).to receive(:last_response).and_return(double(:body => "the body"))
        response_body.should == "the body"
      end
    end
  end

  context "headers" do
    put "/orders" do
      header "Accept", "application/json"
      let(:example) { |example| example }

      it "should be sent with the request" do
        example.metadata[:headers].should == { "Accept" => "application/json" }
      end

      context "nested headers" do
        header "Content-Type", "application/json"

        it "does not affect the outer context's assertions" do
          # pass
        end
      end
    end

    put "/orders" do
      header "Accept", :accept

      let(:accept) { "application/json" }
      let(:example) { |example| example }

      it "should be sent with the request" do |example|
        example.metadata[:headers].should == { "Accept" => :accept }
      end

      it "should fill out into the headers" do |example|
        headers.should == { "Accept" => "application/json" }
      end

      context "nested headers" do
        header "Content-Type", "application/json"

        it "does not affect the outer context's assertions" do
          headers.should == { "Accept" => "application/json", "Content-Type" => "application/json" }
        end
      end

      context "header was not let" do
        header "X-My-Header", :my_header

        it "should not be in the headers hash" do
          headers.should == { "Accept" => "application/json" }
        end
      end
    end
  end
end

resource "top level parameters" do
  parameter :page, "Current page"

  it 'should have 1 parameter' do |example|
    example.metadata[:parameters].length.should == 1
  end
end

resource "passing in document to resource", :document => :not_all do
  it "should have the correct tag" do |example|
    example.metadata[:document].should == :not_all
  end
end
