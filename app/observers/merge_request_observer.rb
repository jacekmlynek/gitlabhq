class MergeRequestObserver < BaseObserver
  def after_create(merge_request)
    event_service.open_mr(merge_request, current_user)
    notification.new_merge_request(merge_request, current_user)
    merge_request.create_cross_references!(merge_request.project, current_user)
    execute_hooks(merge_request)
  end

  def after_close(merge_request, transition)
    event_service.close_mr(merge_request, current_user)
    notification.close_mr(merge_request, current_user)
    create_note(merge_request)
    execute_hooks(merge_request)
  end

  def after_reopen(merge_request, transition)
    event_service.reopen_mr(merge_request, current_user)
    create_note(merge_request)
    execute_hooks(merge_request)
    merge_request.reload_code
    merge_request.mark_as_unchecked
  end

  def after_update(merge_request)
    notification.reassigned_merge_request(merge_request, current_user) if merge_request.is_being_reassigned?

    merge_request.notice_added_references(merge_request.project, current_user)
    execute_hooks(merge_request)
  end

  private

  # Create merge request note with service comment like 'Status changed to closed'
  def create_note(merge_request)
    Note.create_status_change_note(merge_request, merge_request.target_project, current_user, merge_request.state, nil)
  end

  def execute_hooks(merge_request)
    if merge_request.project
      merge_request.project.execute_hooks(merge_request.to_hook_data, :merge_request_hooks)
    end
  end
end
