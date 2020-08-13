defmodule Proj1 do
  use Supervisor

  def start_link(lowerRange, upperRange) do
    Supervisor.start_link(__MODULE__, [lowerRange, upperRange])
  end

  def init([lowerRange, upperRange]) do
    {:ok, bosspid} = Boss.start_link
    rangelist = Enum.filter((for x <- lowerRange..upperRange, x != 0, do: x), fn x -> rem(x, 100) == 0 end)
    children = Enum.map(rangelist, fn(range_num) ->
      worker(Child, [bosspid,range_num], [id: range_num, restart: :permanent])
    end)
    supervise(children, strategy: :one_for_one)
  end
end

defmodule Child do
  use GenServer

  def start_link(bosspid,range_num) do
    GenServer.start_link(__MODULE__, [])
    pid = spawn_link(__MODULE__, :init2, [bosspid, range_num])
    {:ok, pid}
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def init2(bosspid, lowerRange) do
    findFangs(bosspid, lowerRange)
  end

  #Algorithm for finding fangs refer: https://rosettacode.org/wiki/Vampire_number
  def findFangs(bosspid, lowerRange) do
    upperRange = lowerRange + 99
    Enum.reduce_while(lowerRange..upperRange, 0, fn n, acc ->
      case vampire(n) do
        [] ->
          {:cont, acc}
        fang ->
            case length(fang) do
              2 ->
                [[a,b],[c,d]] = fang
                Boss.showresult(bosspid, "#{n} #{a} #{b} #{c} #{d}")
              3 ->
                [[a,b],[c,d],[e,f]] = fang
                Boss.showresult(bosspid, "#{n} #{a} #{b} #{c} #{d} #{e} #{f}")
              1 ->
                [[a,b]] = fang
                Boss.showresult(bosspid, "#{n} #{a} #{b}")
          end
          if acc < upperRange, do: {:cont, acc + 1}, else: {:halt, acc + 1}
      end
    end)
  end

  def fangs(n) do
    first = trunc(n / :math.pow(10, div(length(to_charlist(n)), 2)))
    last = :math.sqrt(n) |> round
    for i <- first..last, rem(n, i) == 0, do: [i, div(n, i)]
  end

  def vampire(n) do
    if rem(length(to_charlist(n)), 2) == 1 do
      []
    else
      half = div(length(to_charlist(n)), 2)
      sorted = Enum.sort(String.codepoints("#{n}"))
      Enum.filter(fangs(n), fn [a, b] ->
        length(to_charlist(a)) == half && length(to_charlist(b)) == half &&
          Enum.sort(String.codepoints("#{a}#{b}")) == sorted &&
          Enum.count([a, b], fn x -> rem(x, 10) == 0 end) != 2
      end)
    end
  end
end

defmodule Boss do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(init_arg) do
      {:ok, init_arg}
  end

  def showresult(pid, result) do
    GenServer.cast(pid, result)
  end

  def handle_cast(result, state) do
    IO.puts "#{result}"
    {:noreply, state}
  end
end

[lowerBound, upperBound] =
  System.argv()
  |> Enum.map(&String.to_integer/1)

Proj1.start_link(lowerBound, upperBound)
