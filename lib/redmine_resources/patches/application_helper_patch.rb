module RedmineResources
  module Patches
    module ApplicationHelperPatch
      def self.included(base)
        base.class_eval do
          def authorize_globally_for(controller, action)
            User.current.allowed_to_globally?({ controller: controller,
              action: action }, {})
          end

          def resources_visible(issue, project)
            return false unless issue.tracker.can_view_resources(project)
            return true if User.current.admin?
            roles = User.current.roles_for_project project
            visible = false
            roles.each {|role| visible = role.can_view_resources(project) if !visible }
            visible
          end

          def resources_editable(issue, project)
            return false unless issue.tracker.can_view_resources(project)
            return true if User.current.admin?
            roles = User.current.roles_for_project project
            trackers = issue.tracker
            visible = false
            roles.each {|role| visible = role.can_edit_resources(project) if !visible }
            visible
          end

          def resources_for_project(project, issue = nil)
            resources = {}
            created_resources = issue.nil? ? [] : issue.resource
            project.resource.each do |resource|
              condition = resource.nil? || created_resources.include?(resource)
              resources[resource.id] = resource unless condition
            end
            resources
          end
        end
      end
    end
  end
end

base = ApplicationHelper
patch = RedmineResources::Patches::ApplicationHelperPatch
base.send :include, patch unless base.included_modules.include? patch
