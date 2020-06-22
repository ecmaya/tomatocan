class EventsController < ApplicationController
#  before_action :authenticate_user!, except: [:index, :show]
  before_action :authenticate_user!, only: [:edit, :update, :new, :create]

  def index
    @events = Event.upcoming.recent
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @events }
    end
  end
    # GET /events/1.json
  def show
    @event     = Event.find(params[:id])
    @user      = User.find(@event.usrid)
    @rsvp      = Rsvpq.new
    @rsvpusers = @event.users
    @rsvps     = @event.rsvpqs
    @duration  = ((@event.end_at - @event.start_at) / 60).floor
    @surl = "http://www.ThinQ.tv/" + @user.permalink

    pdtnow = Time.now - 7.hours + 5.minutes
    id = @user.id
    currconvo = Event.where( "start_at < ? AND end_at > ? AND usrid = ?", pdtnow, pdtnow, id ).first
    if currconvo.present?
      @displayconvo = currconvo
    end  

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @event }
    end
  end

  # GET /events/new.json
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
  end

  # POST /events.json
  def create

    convert_time # call convert time method
    @event = current_user.events.build(event_params)
	
	#parecer ser que todo funciona nms pruebala otra vez y checa la base de datos no agrege cosas que no debe de y desaste de los espacios de mas.
	
	print "\n\n\n\n\n\n\nAQUI EMPIEZA LA FUNCION\n#{@event.name}\n\n\n\n\n\n\n" #BORRA ESTO
    
	@event.name = (@event.name).strip #removes front and trailing spaces
	
	print"\neste es todo el string (#{@event.name})\n\n"
	
	if(@event.name != "")
		@event.update_attribute(:user_id, params[:event][:usrid])
		user = User.find(@event.usrid)
		offset = -1 * Time.now.in_time_zone("Pacific Time (US & Canada)").gmt_offset/3600
		reminder_hour = @event.start_at + offset.hours - 1.hours
		@reminder_date = @event.start_at - 1.days #why is the scope beyond local? Do we use this variable in a view? I doubt it.
	end # if @even.name != "" ends here
	respond_to do |format|
	  if @event.save
		EventMailer.with(user: user , event: @event).event_reminder.deliver_later(wait_until: @reminder_date)
		EventMailer.with(user: user , event: @event).event_reminder.deliver_later(wait_until:  reminder_hour)
		format.html { redirect_to "/" }
		format.json { render json: @event, status: :created, location: @event }
	  else
		format.html { render action: "new" }
		format.json { render json: @event.errors, status: :unprocessable_entity }
	  end # if @event.save ends here
	end # respond_to ends here
  end # def creat ends here

  # PUT /events/1.json
  def update
    @event = Event.find(params[:id])
    convert_time # call convert time method

    respond_to do |format|
      if @event.update_attributes(event_params)
        update_reminder
        format.html { redirect_to @event }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def convert_time
    curr_time_offset = params[:timeZone]
    now = Time.now
    start_date = Time.new(
      params[:event]["start_at(1i)"], # year
      params[:event]["start_at(2i)"], # month
      params[:event]["start_at(3i)"], # day
      params[:event]["start_at(4i)"], # hour
      params[:event]["start_at(5i)"], # minute
      0,                               # seconds
      params[:timeZone]                # timeZone
    )

    # calculate local time in pacific time
    converted_start_time = start_date.in_time_zone("Pacific Time (US & Canada)")
    converted_end_time = start_date.in_time_zone("Pacific Time (US & Canada)") + 1.hour

    # edit params from local time to pacific time to store in database
    params[:event]["start_at(1i)"] = converted_start_time.year.to_s   # set start year
    params[:event]["start_at(2i)"] = converted_start_time.month.to_s  # set start month
    params[:event]["start_at(3i)"] = converted_start_time.day.to_s    # set start day
    params[:event]["start_at(4i)"] = converted_start_time.hour.to_s   # set start hour
    params[:event]["start_at(5i)"] = converted_start_time.min.to_s # set start mins
    params[:event]["end_at(1i)"] = converted_end_time.year.to_s   # set end year
    params[:event]["end_at(2i)"] = converted_end_time.month.to_s  # set end month
    params[:event]["end_at(3i)"] = converted_end_time.day.to_s    # set end day
    params[:event]["end_at(4i)"] = converted_end_time.hour.to_s   # set end hour
    params[:event]["end_at(5i)"] = converted_end_time.min.to_s # set start mins
  end
  
  def update_reminder
    user = User.find(@event.usrid)
    @reminder_date = @event.start_at - 1.hour 
    EventMailer.with(user: user , event: @event).event_reminder.deliver_later(wait_until: @reminder_date)
  end

  def event_params
    params.require(:event).permit(:topic, :name, :start_at, :end_at, :desc, :usrid, :user_id)
  end
    
end