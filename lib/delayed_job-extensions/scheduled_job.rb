# Migration:
#
# create_table "scheduled_jobs", force: :cascade do |t|
#   t.string   "kind"                     # cron etc
#   t.string   "trigger"                  # '* * * * *'
#   t.text     "options"                  # options for scheduler
#   t.boolean  "active", default: true    # on/off scope
#
#   t.text     "block"                    # ruby to eval
#
#   t.string   "queue"                    # dj queue
#
#   t.string   "name"
#   t.string   "category"
#   t.string   "timing"
#
#   t.timestamps
# end
#
# Rufus install:
#
# ScheduledJob.grouped_by_kind_trigger.each do |kind_trigger, jobs|
#   kind, trigger = kind_trigger
#   scheduler.add("scheduler.#{kind}.#{trigger}", kind, trigger, jobs: jobs.map(&:full_name)) do
#     jobs.each(&:queue_job)
#   end
# end
#
class ScheduledJob < ActiveRecord::Base
  serialize :options

  #
  # Validations
  #

  validates :kind, :trigger, :block, presence: true

  #
  # Named Scopes
  #

  scope :active, -> { where(active: true) }
  scope :matching_schedule, proc { |job|
    kind, trigger = job.respond_to?(:kind_trigger) ? job.kind_trigger : job
    where(kind: kind, trigger: trigger)
  }

  scope :search, -> (query) { where("CONCAT(category,timing,name,block) LIKE ?", "%#{query}%") }

  #
  # Class
  #

  class << self
    # Select a job, edit and save, then return to job list
    def editor(editor = nil)
      while true
        edit!(editor)
      end
    end

    # Select a job, edit it and return it unsaved
    def edit(editor = nil)
      job = gets_job
      job.edit(editor)
      job
    end

    # Select a job, edit and save it, then return to console
    def edit!(editor = nil)
      job = gets_job
      job.edit!(editor)
      job
    end

    def grouped_by_kind_trigger
      active.group_by(&:kind_trigger)
    end

    private

    def gets_job
      print_table

      job = nil

      until job
        puts 'Enter Job ID to edit:'
        job_id = gets.chomp
        break if job_id.empty?
        job = find_by_id job_id
      end

      job
    end

    def print_table
      puts order('is_online, category, timing, name').all.map(&:as_row).join("\n")
    end
  end

  #
  # Instances
  #

  def args
    [kind, trigger, options.to_options]
  end

  # args allow you to pass details that will show up in DJ/Loggly logs
  def call(*args)
    eval(block) # rubocop:disable all
  end

  alias_method :run, :call

  def full_name
    "##{id} - #{category} (#{timing}): #{name}"
  end

  def kind_trigger
    [kind, trigger]
  end

  def options
    super || {}
  end

  # insert into DJ
  # 5 sec delay to guard against any issues with parallel schedulers running.
  def queue_job
    delay(queue: queue || 'any', priority: -1, run_once_in: 5.seconds).call(full_name)
  end

  def schedule
    "#{kind} #{trigger}"
  end

  #
  # Editing
  #

  # Open block in editor
  def edit_block(editor = nil)
    self.block = String.edit(block, editor)
  end

  def edit_options(editor = nil)
    attrs = attributes.except(
      'created_at', 'updated_at', 'created_by', 'updated_by', 'id', 'options', 'block'
    )
    yaml = String.edit(attrs.to_yaml, editor)
    self.attributes = YAML.safe_load(yaml)
  end

  def edit(editor = nil)
    edit_block(editor)
    edit_options(editor)
  end

  def edit!(editor = nil)
    edit(editor)
    save!
  end

  # Job as a row for ScheduledJob.print_table
  def as_row
    [
      [id, -4],
      [category, 15],
      [name, 50],
      [timing, -15],
      [trigger, -15],
      [queue, 15]
    ].map do |value, padding|
      if padding > 0
        value.to_s.ljust(padding)
      else
        value.to_s.rjust(padding.abs)
      end
    end.join(' | ')
  end
end
