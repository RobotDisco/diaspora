#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'spec_helper'

describe Post do
  before do
    @user = alice
    @aspect = @user.aspects.create(:name => "winners")
  end

  describe 'deletion' do
    it 'should delete a posts comments on delete' do
      post = Factory.create(:status_message, :author => @user.person)
      @user.comment "hey", :on => post
      post.destroy
      Post.where(:id => post.id).empty?.should == true
      Comment.where(:text => "hey").empty?.should == true
    end
  end

  describe 'serialization' do
    it 'should serialize the handle and not the sender' do
      post = @user.post :status_message, :text => "hello", :to => @aspect.id
      xml = post.to_diaspora_xml

      xml.include?("person_id").should be false
      xml.include?(@user.person.diaspora_handle).should be true
    end
  end

  describe '#mutable?' do
    it 'should be false by default' do
      post = @user.post :status_message, :text => "hello", :to => @aspect.id
      post.mutable?.should == false
    end
  end

  describe '#subscribers' do
    it 'returns the people contained in the aspects the post appears in' do
      post = @user.post :status_message, :text => "hello", :to => @aspect.id

      post.subscribers(@user).should == []
    end

    it 'returns all a users contacts if the post is public' do
      post = @user.post :status_message, :text => "hello", :to => @aspect.id, :public => true

      post.subscribers(@user).to_set.should == @user.contact_people.to_set
    end
  end

  describe '#receive' do
    it 'saves public posts' do
      #this is done via GET so no need to check for contact
      post = Factory.build(:status_message, :author_id => eve.person.id, :public => true)
      lambda{
        post.receive(alice, eve.person)
      }.should change{
        Post.count
      }.by(1)

    end
  end
end
