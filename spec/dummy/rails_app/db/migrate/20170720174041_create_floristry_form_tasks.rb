class CreateFloristryFormTasks < ActiveRecord::Migration
  def change
    create_table :floristry_form_tasks do |t|
      t.string :__feid__
      t.text :__msg__
      t.string :current_state

      t.text :free_text

      t.timestamps
    end
  end
end
