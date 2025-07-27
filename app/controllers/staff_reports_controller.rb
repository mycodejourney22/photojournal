# app/controllers/staff_reports_controller.rb
# Simplified version that avoids complex GROUP BY operations
class StaffReportsController < ApplicationController
    before_action :set_date_filters
    before_action :set_location_filter
    before_action :set_staff_filter
    
    def index
      authorize :staff_report, :index?
      
      # Get filtered photoshoots
      @photoshoots = filter_photoshoots
      
      # Calculate metrics for photographers and editors
      @photographer_stats = calculate_photographer_stats
      @editor_stats = calculate_editor_stats
      @combined_staff_stats = calculate_combined_staff_stats
      
      # Location breakdown (simplified)
      @location_breakdown = calculate_location_breakdown_simple
      
      # Daily performance data for charts
      @daily_performance_data = calculate_daily_performance
      
      # Summary metrics
      @total_photoshoots = @photoshoots.count
      @completed_photoshoots = @photoshoots.where(status: 'Sent').count
      @pending_photoshoots = @photoshoots.where(status: 'Pending').count
      @new_photoshoots = @photoshoots.where(status: 'New').count
      @average_selections = @photoshoots.where.not(number_of_selections: nil).average(:number_of_selections)&.round(1) || 0
      
      respond_to do |format|
        format.html
        format.csv { send_csv_export }
        format.json { render json: performance_json_data }
      end
    end
    
    def photographer_detail
      authorize :staff_report, :show?
      @photographer = Staff.find(params[:photographer_id])
      @photoshoots = filter_photoshoots.where(photographer: @photographer)
      @detailed_stats = calculate_detailed_photographer_stats_simple(@photographer)
    end
    
    def editor_detail
      authorize :staff_report, :show?
      @editor = Staff.find(params[:editor_id])
      @photoshoots = filter_photoshoots.where(editor: @editor)
      @detailed_stats = calculate_detailed_editor_stats_simple(@editor)
    end
    
    private
    
    def set_date_filters
      case params[:period]
      when 'today'
        @start_date = Date.current
        @end_date = Date.current
      when 'yesterday'
        @start_date = Date.yesterday
        @end_date = Date.yesterday
      when 'this_week'
        @start_date = Date.current.beginning_of_week
        @end_date = Date.current
      when 'last_week'
        @start_date = 1.week.ago.beginning_of_week
        @end_date = 1.week.ago.end_of_week
      when 'this_month'
        @start_date = Date.current.beginning_of_month
        @end_date = Date.current
      when 'last_month'
        @start_date = 1.month.ago.beginning_of_month
        @end_date = 1.month.ago.end_of_month
      when 'custom'
        @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
        @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current
      else
        @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
        @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current
      end
      
      # Ensure dates are valid
      @end_date = [@end_date, Date.current].min
      @start_date = [@start_date, @end_date].min
      
      @selected_period = params[:period] || 'custom'
    end
    
    def set_location_filter
      @selected_location = params[:location].present? && params[:location] != 'all' ? params[:location] : nil
      @available_locations = ['Ajah', 'Ikeja', 'Surulere']
    end
    
    def set_staff_filter
      @selected_staff_type = params[:staff_type] || 'all'
      @selected_staff_id = params[:staff_id].present? ? params[:staff_id].to_i : nil
    end
    
    def filter_photoshoots
      scope = PhotoShoot.joins(:appointment)
                       .includes(:photographer, :editor, :customer_service, :appointment)
                       .where(date: @start_date..@end_date)
      
      scope = scope.where(appointments: { location: @selected_location }) if @selected_location
      scope = scope.where(photographer_id: @selected_staff_id) if @selected_staff_type == 'photographer' && @selected_staff_id
      scope = scope.where(editor_id: @selected_staff_id) if @selected_staff_type == 'editor' && @selected_staff_id
      
      scope.order(date: :desc)
    end
    
    def calculate_photographer_stats
      photographers = Staff.where(role: 'Photographer', active: true)
      
      photographers.map do |photographer|
        shoots = @photoshoots.where(photographer: photographer)
        
        # Calculate location distribution manually
        location_counts = {}
        shoots.includes(:appointment).each do |shoot|
          location = shoot.appointment.location
          location_counts[location] = (location_counts[location] || 0) + 1
        end
        
        {
          staff: photographer,
          total_shoots: shoots.count,
          completed_shoots: shoots.where(status: 'Sent').count,
          pending_shoots: shoots.where(status: 'Pending').count,
          new_shoots: shoots.where(status: 'New').count,
          total_selections: shoots.sum(:number_of_selections) || 0,
          average_selections: shoots.where.not(number_of_selections: nil).average(:number_of_selections)&.round(1) || 0,
          completion_rate: shoots.count > 0 ? (shoots.where(status: 'Sent').count.to_f / shoots.count * 100).round(1) : 0,
          locations: location_counts
        }
      end.reject { |stat| stat[:total_shoots] == 0 }
    end
    
    def calculate_editor_stats
      editors = Staff.where(role: 'Editor', active: true)
      
      editors.map do |editor|
        shoots = @photoshoots.where(editor: editor)
        
        # Calculate location distribution manually
        location_counts = {}
        shoots.includes(:appointment).each do |shoot|
          location = shoot.appointment.location
          location_counts[location] = (location_counts[location] || 0) + 1
        end
        
        {
          staff: editor,
          total_shoots: shoots.count,
          completed_edits: shoots.where(status: 'Sent').count,
          pending_edits: shoots.where(status: 'Pending').count,
          new_assignments: shoots.where(status: 'New').count,
          total_selections_edited: shoots.where(status: 'Sent').sum(:number_of_selections) || 0,
          average_selections_per_shoot: shoots.where.not(number_of_selections: nil).average(:number_of_selections)&.round(1) || 0,
          completion_rate: shoots.count > 0 ? (shoots.where(status: 'Sent').count.to_f / shoots.count * 100).round(1) : 0,
          locations: location_counts
        }
      end.reject { |stat| stat[:total_shoots] == 0 }
    end
    
    def calculate_combined_staff_stats
      staff_members = Staff.where(role: ['Photographer', 'Editor'], active: true)
      
      staff_members.map do |staff|
        if staff.role == 'Photographer'
          shoots = @photoshoots.where(photographer: staff)
          metric_name = 'Shoots'
        else
          shoots = @photoshoots.where(editor: staff)
          metric_name = 'Edits'
        end
        
        {
          staff: staff,
          role: staff.role,
          total_work: shoots.count,
          completed_work: shoots.where(status: 'Sent').count,
          pending_work: shoots.where(status: 'Pending').count,
          new_work: shoots.where(status: 'New').count,
          metric_name: metric_name,
          completion_rate: shoots.count > 0 ? (shoots.where(status: 'Sent').count.to_f / shoots.count * 100).round(1) : 0
        }
      end.reject { |stat| stat[:total_work] == 0 }
    end
    
    def calculate_location_breakdown_simple
      breakdown = {}
      
      @available_locations.each do |location|
        location_shoots = @photoshoots.joins(:appointment).where(appointments: { location: location })
        
        breakdown[location] = {
          'Total' => location_shoots.count,
          'Sent' => location_shoots.where(status: 'Sent').count,
          'Pending' => location_shoots.where(status: 'Pending').count,
          'New' => location_shoots.where(status: 'New').count
        }
      end
      
      breakdown
    end
    
    def calculate_daily_performance
      daily_data = []
      
      (@start_date..@end_date).each do |date|
        day_shoots = @photoshoots.where(date: date)
        
        daily_data << {
          date: date,
          total_shoots: day_shoots.count,
          completed_shoots: day_shoots.where(status: 'Sent').count,
          photographers_active: day_shoots.distinct.count(:photographer_id),
          editors_active: day_shoots.distinct.count(:editor_id),
          total_selections: day_shoots.sum(:number_of_selections) || 0
        }
      end
      
      daily_data
    end
    
    def calculate_detailed_photographer_stats_simple(photographer)
      shoots = @photoshoots.where(photographer: photographer)
      
      # Daily breakdown
      daily_breakdown = {}
      shoots.each do |shoot|
        date_key = shoot.date.to_s
        daily_breakdown[date_key] ||= {}
        daily_breakdown[date_key][shoot.status] = (daily_breakdown[date_key][shoot.status] || 0) + 1
      end
      
      # Location breakdown
      location_breakdown = {}
      shoots.includes(:appointment).each do |shoot|
        location = shoot.appointment.location
        location_breakdown[location] ||= {}
        location_breakdown[location][shoot.status] = (location_breakdown[location][shoot.status] || 0) + 1
      end
      
      # Editor collaboration
      editor_collaboration = {}
      shoots.includes(:editor).each do |shoot|
        next unless shoot.editor
        editor_name = shoot.editor.name
        editor_collaboration[editor_name] = (editor_collaboration[editor_name] || 0) + 1
      end
      
      {
        daily_breakdown: daily_breakdown,
        location_breakdown: location_breakdown,
        editor_collaboration: editor_collaboration
      }
    end
    
    def calculate_detailed_editor_stats_simple(editor)
      shoots = @photoshoots.where(editor: editor)
      
      # Daily breakdown
      daily_breakdown = {}
      shoots.each do |shoot|
        date_key = shoot.date.to_s
        daily_breakdown[date_key] ||= {}
        daily_breakdown[date_key][shoot.status] = (daily_breakdown[date_key][shoot.status] || 0) + 1
      end
      
      # Location breakdown
      location_breakdown = {}
      selections_by_location = {}
      shoots.includes(:appointment).each do |shoot|
        location = shoot.appointment.location
        location_breakdown[location] ||= {}
        location_breakdown[location][shoot.status] = (location_breakdown[location][shoot.status] || 0) + 1
        
        if shoot.status == 'Sent' && shoot.number_of_selections
          selections_by_location[location] = (selections_by_location[location] || 0) + shoot.number_of_selections
        end
      end
      
      # Photographer collaboration
      photographer_collaboration = {}
      shoots.includes(:photographer).each do |shoot|
        next unless shoot.photographer
        photographer_name = shoot.photographer.name
        photographer_collaboration[photographer_name] = (photographer_collaboration[photographer_name] || 0) + 1
      end
      
      {
        daily_breakdown: daily_breakdown,
        location_breakdown: location_breakdown,
        selections_by_location: selections_by_location,
        photographer_collaboration: photographer_collaboration
      }
    end
    
    def send_csv_export
      require 'csv'
      
      headers = [
        'Staff Name', 'Role', 'Total Work', 'Completed', 'Pending', 'New', 
        'Completion Rate %', 'Total Selections', 'Avg Selections'
      ]
      
      csv_data = CSV.generate(headers: true) do |csv|
        csv << headers
        
        (@photographer_stats + @editor_stats).each do |stat|
          csv << [
            stat[:staff].name,
            stat[:staff].role,
            stat[:total_shoots] || stat[:total_work],
            stat[:completed_shoots] || stat[:completed_edits] || stat[:completed_work],
            stat[:pending_shoots] || stat[:pending_edits] || stat[:pending_work],
            stat[:new_shoots] || stat[:new_assignments] || stat[:new_work],
            stat[:completion_rate],
            stat[:total_selections] || stat[:total_selections_edited],
            stat[:average_selections] || stat[:average_selections_per_shoot]
          ]
        end
      end
      
      filename = "staff_performance_#{@start_date}_to_#{@end_date}.csv"
      send_data csv_data, filename: filename, type: 'text/csv'
    end
    
    def performance_json_data
      {
        summary: {
          total_photoshoots: @total_photoshoots,
          completed_photoshoots: @completed_photoshoots,
          pending_photoshoots: @pending_photoshoots,
          average_selections: @average_selections
        },
        photographers: @photographer_stats,
        editors: @editor_stats,
        daily_data: @daily_performance_data,
        date_range: {
          start_date: @start_date,
          end_date: @end_date
        }
      }
    end
  end