
class CommandLine
  attr_accessor :filepath, :encryption, :op_file

  def initialize(attributes)
    attributes.each {|attribute, value| self.send("#{attribute}=", value) }
    self.op_file = OPFile.new({filepath: filepath})
  end

  def start_utility
    op_file.filepath = filepath
    print "Analyzing File... "
    show_wait_spinner { op_file.process_file }
    op_file.print_result
  end


  private

  def show_wait_spinner(fps=10)
    # courtesy of Phrogz
    # https://stackoverflow.com/questions/10262235/printing-an-ascii-spinning-cursor-in-the-console

    chars = %w[⣾ ⣷ ⣯ ⣟ ⡿ ⢿ ⣻ ⣽]
    delay = 1.0/fps
    iter = 0
    spinner = Thread.new do
      while iter do  # Keep spinning until told otherwise
        print chars[(iter+=1) % chars.length]
        sleep delay
        print "\b"
      end
    end
    yield.tap{       # After yielding to the block, save the return value
      iter = false   # Tell the thread to exit, cleaning up after itself…
      spinner.join   # …and wait for it to do so.
    }                # Use the block's return value as the method's
  end

end