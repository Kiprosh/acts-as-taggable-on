# -*- encoding : utf-8 -*-
require 'spec_helper'

class ParanoidMigration < ActiveRecord::Migration
  def self.up
    add_column :taggings, :deleted_at, :datetime, default: nil
    ActsAsTaggableOn::Tagging.reset_column_information
  end

  def self.down
    remove_column :taggings, :deleted_at
    ActsAsTaggableOn::Tagging.reset_column_information
  end
end

describe ActsAsTaggableOn::Taggable::Core do
  before :all do
    ParanoidMigration.up
  end

  after :all do
    ParanoidMigration.down
  end

  context 'soft deleted taggings' do
    before(:each) do
      @taggable = TaggableModel.new(name: 'Bob Jones')
    end

    it 'should not be able to find by tag with context' do
      @taggable.skill_list = 'ruby, rails, css'
      @taggable.save

      expect(TaggableModel.tagged_with('ruby').first).to eq(@taggable)

      ActsAsTaggableOn::Tag.where(name: "ruby").first.taggings.each { |t| t.update_column(:deleted_at, Time.now) }

      expect(TaggableModel.tagged_with('ruby').first).to_not eq(@taggable)
      expect(TaggableModel.tagged_with('ruby, css').first).to eq(@taggable)
    end
  end
end
