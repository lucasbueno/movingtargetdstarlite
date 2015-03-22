import jason.asSyntax.*;
import jason.environment.*;
import jason.environment.grid.*;
import java.util.logging.*;
import java.util.*;

import java.awt.Canvas;
import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics;


public class GridMovingTarget extends Environment {
  
  private Random r = new Random();

  public static final int N       = 15;   // largura do grid NxN 
  public static final int minCost = 1;
  public static final int maxCost = 1;
  public static final int delay   = 1000; // delay entre acoes em ms
  //public final int delayFactor = 10;

  public static final int AGENT  = 0;
  public static final int TARGET = 1;

  public static final int CLOSED = 16;
  public static final int OPEN   = 32;
  public static final int TEXT   = 64;

  public int[][] costs;
  /*public int[][] maze = {	
    {1,1,1,1,1},
    {0,0,0,0,1},
    {1,1,1,1,1},
    {1,0,0,0,0},
    {1,1,1,1,1}
    };
    */
    public int targetPosX, targetPosY;
    private String[] agentsName;
    

  public static final Literal percGrid = 
    Literal.parseLiteral("grid(" + N + "," + N + ")");

  private Logger logger = Logger.getLogger("movingTargetSearch.mas2j."+GridMovingTarget.class.getName());

  private MarsModel model;
  private MarsView  view;


  /** Called before the MAS execution with the args informed in .mas2j */

  @Override
  public void init(String[] args) {
    int mSize = (N+1)/2;
    int tx, ty;
    int[][] maze;

    MazeGenerator m = new MazeGenerator(mSize,mSize);
    //m.displayBinary();
    maze = m.getBinaryMaze();
    
    costs = new int[N][N];
    
    for(int y = 0; y < N; y++) {
      for(int x = 0; x < N; x++) {
        costs[x][y] = (maze[y][x] > 0) ? 1 : 1;
      }
    }

    model = new MarsModel(AGENT, TARGET);
    view  = new MarsView(model);
    model.setView(view);
    agentsName = (String[]) args.clone();
    
    updatePerceptions();    
		addPercept(Literal.parseLiteral("matriz(" + N + "," + N + ")"));
  }

  @Override
  public boolean executeAction(String agName, Structure action) {
    boolean ok = true;
    int agId = agNameToId(agName);
		ListTermImpl path = new ListTermImpl();
    
    try {
      Thread.sleep(delay);
      if (action.getFunctor().equals("right")) {
        model.moveRight(agId);
      } else if (action.getFunctor().equals("left")) {
        model.moveLeft(agId);
      } else if (action.getFunctor().equals("up")) {
        model.moveUp(agId);
      } else if (action.getFunctor().equals("down")) {
        model.moveDown(agId);
      } else if (action.getFunctor().equals("moveTo")) {
				int x = (int) ((NumberTerm) action.getTerm(0)).solve();
				int y = (int) ((NumberTerm) action.getTerm(1)).solve();
         logger.info("movendo para (" + x + "," + y + ")");
				model.moveTo(agId, x-1, y-1);
			} else if (action.getFunctor().equals("nextMov")){
				model.nextMov(agId);
			} else if (action.getFunctor().equals("search")) {
				path = movingTargetDStar();
			} else if (action.getFunctor().equals("nop")){
        
			} else {
        logger.info("executing: "+action+", but not implemented!");
        ok = false;
        return false;
      }
    } catch (Exception e) {
      logger.info("exception: " + e.getMessage());
    }

    updateAgPercept(agId);    
		if (path.size() > 0) {
      Location taLoc = model.getAgPos(TARGET);
			addPercept(agName, ASSyntax.createLiteral(
                            "novoPlano", 
                            //ASSyntax.createNumber(taLoc.x+1), 
                            //ASSyntax.createNumber(taLoc.y+1),
                            path) );
		}

    return true;
  }
  
  
  private ListTermImpl movingTargetDStar() {
		
    Location agLoc = model.getAgPos(AGENT);
    Location taLoc = model.getAgPos(TARGET);
    ListTermImpl path = new ListTermImpl();
    
		while (agLoc.x != taLoc.x || agLoc.y != taLoc.y) {
      if (agLoc.x < taLoc.x) {
				agLoc.x++;
      } else if (agLoc.x > taLoc.x) {
				agLoc.x--;
      } else if (agLoc.y < taLoc.y) {
				agLoc.y++;
      } else if (agLoc.y > taLoc.y) {
				agLoc.y--;
      }      
			path.add(ASSyntax.createLiteral("moveTo", 
						ASSyntax.createNumber(agLoc.x+1),
						ASSyntax.createNumber(agLoc.y+1)
						));
		}
    return path;
  }
  

  /** Called before the end of MAS execution */

  @Override
  public void stop() {
    super.stop();
  }

  public void updatePerceptions() {
		
		for (int i = 0; i < model.getNbOfAgs(); i++) {
      updateAgPercept(i);
    }
	}
  
  public void updateAgPercept(int ag) {
    clearPercepts();
    
    Location agLoc = model.getAgPos(ag);
    Literal posPerc = Literal.parseLiteral(
        "pos(" + (agLoc.x+1) + "," + (agLoc.y+1) + ")");
    addPercept(agentsName[ag], posPerc);
    
    //if (ag == AGENT) {
      Location tLoc = model.getAgPos(TARGET);
      Literal targetPosPerc = Literal.parseLiteral(
          "target(" + (tLoc.x+1) + "," + (tLoc.y+1) + ")");
      //addPercept(agentsName[ag], targetPosPerc);
      addPercept(targetPosPerc);
    //}
  }

  public int agNameToId(String name) {
    if(name.contains("agent"))
      return AGENT;
    else if (name.equals("target"))
      return TARGET;
    else
      return -1;
  }
  

  class MarsModel extends GridWorldModel {

    private MarsModel(int idAgent, int idTarget) {
      super(N, N, 2);

      Location aLoc, tLoc;

      // posicao inicial aleatoria
      try {
        aLoc = generateRandomLoc();
        tLoc = generateRandomLoc();
        setAgPos(idAgent, aLoc.x, aLoc.y);
        setAgPos(idTarget, tLoc.x, tLoc.y);
      } catch (Exception e) {
        e.printStackTrace();
      }

      for(int y = 0; y < N; y++) {
        for(int x = 0; x < N; x++) {
          if(costs[y][x] == 0)
            add(OBSTACLE, x, y);
          else
            add(GridMovingTarget.TEXT, x, y);
        }
      }
    }
     
    Location generateRandomLoc() {
      int x,y;
      do {
        x = r.nextInt(N);
        y = r.nextInt(N);
      } while(costs[y][x] == 0);
      return new Location(x,y);
    }

    @Override
    public void setAgPos(int ag, Location l) {
      super.setAgPos(ag, l);
    }

    @Override
    public void setAgPos(int ag, int x, int y) {
      setAgPos(ag, new Location(x, y));
    }
    
    void moveTo(int ag, int x, int y) throws Exception {
      Location agLoc = getAgPos(ag);
			if (agLoc.x < x) {
				moveRight(ag);
      } else if (agLoc.x > x) {
				moveLeft(ag);
      } else if (agLoc.y < y) {
				moveDown(ag);
      } else if (agLoc.y > y) {
				moveUp(ag);
      }
		}
        
		boolean nextMov(int ag) throws Exception {
      boolean ok = false;
      while(!ok) {	
        int nextPos = r.nextInt(4);		
        switch (nextPos) {			
            case 0:
              ok = moveUp(ag);
              break;
            case 1:
              ok = moveDown(ag);
              break;
            case 2:
              ok = moveLeft(ag);
              break;
            case 3:
              ok = moveRight(ag);
              break;					
        }
      }
			return true;
		}

    boolean moveRight(int ag) throws Exception {
      Location agLoc = getAgPos(ag);
      if (agLoc.x < N-1 && costs[agLoc.y][agLoc.x+1] > 0) {
        agLoc.x++;
        setAgPos(ag, agLoc);
        return true;
      }
      return false;
    }

    boolean moveLeft(int ag) throws Exception {
      Location agLoc = getAgPos(ag);
      if (agLoc.x > 0 && costs[agLoc.y][agLoc.x-1] > 0) {
        agLoc.x--;
        setAgPos(ag, agLoc);
        return true;
      }
      return false;
    } 

    boolean moveUp(int ag) throws Exception {
      Location agLoc = getAgPos(ag);
      if (agLoc.y > 0 && costs[agLoc.y-1][agLoc.x] > 0) {
        agLoc.y--;
        setAgPos(ag, agLoc);
        return true;
      }
      return false;
    }    

    boolean moveDown(int ag) throws Exception {
      Location agLoc = getAgPos(ag);
      if (agLoc.y < N-1 && costs[agLoc.y+1][agLoc.x] > 0) {
        agLoc.y++;
        setAgPos(ag, agLoc);
        return true;
      }
      return false;
    }
  }

  class MarsView extends GridWorldView {

    int agId;
    Font costsFont;

    public MarsView(MarsModel model) {
      super(model, "Mars World", 600);
      defaultFont = new Font("Arial", Font.BOLD, 18); // change default font
      setVisible(true);
      repaint();
    }

    /** draw application objects */
    @Override
    public void draw(Graphics g, int x, int y, int object) {
      switch(object) {
        case GridMovingTarget.CLOSED: drawVisited(g, x, y);
                                      break;
        case GridMovingTarget.TEXT: 	drawText(g, x, y);
                                      break;
        case GridMovingTarget.OPEN:   drawNeighbor(g, x, y);
                                      break;
      }
    }

    public void drawVisited(Graphics g, int x, int y) {
      g.setColor(Color.cyan);
      g.fillRect(x*cellSizeW, y*cellSizeH, cellSizeW, cellSizeH);
      g.setColor(Color.lightGray);
      g.drawRect(x*cellSizeW, y*cellSizeH, cellSizeW, cellSizeH);
    }

    @Override
    public void drawAgent(Graphics g, int x, int y, Color c, int id) {
      c = new Color(255, 255, 0);
      super.drawAgent(g, x, y, c, -1);
      g.setColor(Color.black);
      if (id == GridMovingTarget.AGENT)
        drawString(g, x, y, defaultFont, "A");
      else if (id == GridMovingTarget.TARGET)
        drawString(g, x, y, defaultFont, "T");
    }

    public void drawNeighbor(Graphics g, int x, int y) {			
      g.setColor(Color.green);
      g.fillOval(x*this.cellSizeW+2, y*this.cellSizeH+2,
          this.cellSizeW-4, this.cellSizeH-4);
    }

    public void drawText(Graphics g, int x, int y) {
      int fSize = cellSizeW/4;
      if(costsFont == null)
        costsFont = new Font("Arial", Font.BOLD, fSize);
      g.setColor(Color.black);
      g.setFont(costsFont);
      if (costs[y][x] >= 0)
        g.drawString(String.valueOf(costs[y][x]), x*cellSizeW, y*cellSizeH+fSize);
      else
        g.drawString("inf", x*cellSizeW, y*cellSizeH+fSize);
    }

  }

}


