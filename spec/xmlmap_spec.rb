require './lib/xmlmap'

RSpec.describe Xmlmap do
  context "when inherited" do
		it "adds the @xml_map var to the children class" do
	    class SomeXmlFeed < Xmlmap
			end

			expect(SomeXmlFeed.instance_variables).to include(:@xml_map)
		end

	  it "adds a set_url class method to the inheritor class" do
			class SomeXmlFeed < Xmlmap
			end

			expect(SomeXmlFeed.methods).to include(:set_url)
		end

    it "the set_url class method on the inheritor class saves the url" do
      class SomeXmlFeed < Xmlmap
        set_url './spec/games.xml'
			end			

      expect(SomeXmlFeed.instance_variable_get(:@xml_map)[:url]).to eq('./spec/games.xml') 
		end

		it "the set_url class method on the inheritor class creates a Nokogiri::XML object with the xml at the url" do
      class SomeXmlFeed < Xmlmap
        set_url './spec/games.xml'
			end			

      expect(SomeXmlFeed.instance_variable_get(:@xml_map)[:xml_object]).to be_a(Nokogiri::XML::Document) 
		end
	end

  
end
