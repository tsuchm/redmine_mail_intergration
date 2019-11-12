#coding:utf-8
require_dependency 'mail_handler'
require_dependency '../app/models/mail_message.rb'

module MailIntergrationPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method :dispatch_without_more_integration, :dispatch
      alias_method :dispatch, :dispatch_with_more_integration
    end
  end

  module InstanceMethods
    def dispatch_with_more_integration
      if email.in_reply_to
        msg = MailMessage.find_by_message_id_and_username(email.in_reply_to, ENV['username'])
      elsif email.references
        msg = MailMessage.find_by_message_id_and_username(email.references, ENV['username'])
      else
        msg = false
      end

      if msg
        journal = receive_issue_reply(msg.issue_id)
        issue = journal.issue
      else
        journal_or_issue = dispatch_without_more_integration
        if journal_or_issue.respond_to? :issue
          journal = journal_or_issue
          issue = journal_or_issue.issue
        else
          journal = false
          issue = journal_or_issue
        end
      end

      if issue
        msg = MailMessage.find_by_message_id_and_username(email.message_id, ENV['username']) || MailMessage.new
        msg.message_id = email.message_id
        msg.issue_id = issue.id
        msg.username = ENV['username']
        msg.save!
      end

      if journal
        journal
      else
        issue
      end
    end
  end
end
