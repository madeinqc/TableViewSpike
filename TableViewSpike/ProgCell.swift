//
//  ProgCell.swift
//  TableViewSpike
//
//  Created by Alexis Gallagher on 2015-05-18.
//  Copyright (c) 2015 Bloom Filter. All rights reserved.
//

import UIKit

/**

This programatically created cell correctly sizes around its multi-line label
content within a view controller where the table view has set the
estimatedRowHeight.

Note well what was done:
1. contraints are configured against contentView, not agains the cell itself
2. UILabel.numberOfLines = 0, to enable line wrapping

Note also what was NOT done:
1. we did not install the constraints in UIView.updateConstraints. (We did it in init)
2. we did not set UILabel.preferredMaxLayoutWidth
3. we did not set any content-hugging or compression-resistance priorities
4. we did not add a combination of constraints, with a lower priority constraint
   driving the contentView to shrink locally, and a higher priority constraint
   stopping it from compressing its content

*/

class ProgCell : UITableViewCell
{
  var bodyLabel:UILabel!
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: UITableViewCellStyle.default, reuseIdentifier: reuseIdentifier)
    
    super.contentView.backgroundColor = UIColor.gray
    
    self.bodyLabel = UILabel(frame: self.bounds)
    self.bodyLabel.numberOfLines = 0
    self.bodyLabel.backgroundColor = UIColor.yellow
    self.contentView.addSubview(bodyLabel)
    
    // AL setup
    self.bodyLabel.translatesAutoresizingMaskIntoConstraints =  false
    let vfls = ["H:|-15-[bodyLabel]-15-|","V:|-15-[bodyLabel]-15-|"]
    for vfl in vfls {
      self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: vfl, options:[] , metrics: nil, views: ["bodyLabel":self.bodyLabel]))
    }

//    self.installNon44PtHeightConstraint(.Cell)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
  }
  
  override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
    let result = super.systemLayoutSizeFitting(targetSize)
    return result
  }
  
  override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
//    NSLog("existing constraints on cell.contentView.label: %@", bodyLabel.constraintsAffectingLayoutForAxis(.Vertical))
//    NSLog("existing constraints on cell.contentView: %@", self.contentView.constraintsAffectingLayoutForAxis(.Vertical))
//    NSLog("existing constraints on cell: %@", self.constraintsAffectingLayoutForAxis(.Vertical))
    let result = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
    
    return result
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  enum HeightConstraintLocation {
    case cell, contentView, contentViewSubview
  }

  /** Adds a constraint somewhere in the cell that is incompatible with a height of 44 pt.
  
  
  @discussion This is in order to facilitate exploration of how to workaround some of of UIKit's 
  frustrating built-in system constraints
  */
  func installNon44PtHeightConstraint(_ location:HeightConstraintLocation) {
    /*
    ## Parenthetical Discussion of Constraint Errors
    ## Due to the Notorious "UIView-Encapsulated-Layout-Height" Constraint
    
    The constraints below allow you to configure the cell to add an additional requirement of
    a minimum height of 50, to cell, its contentview, or the label. This is in order to simulate
    the behavior of other cell designs, which have a height greater than 44 on initialization.
    
    Why is this interesting? It is interesting because such cells will sometimes start out
    in conflict with temporary UIKit constraints that set the cell to the default height of 44.
    
    When a UITableView using auto-sizing logic first runs, it initializes
    the cell, calls `tableView(_:cellForRowAtIndexPath:)` in order to populate the cell with content,
    and then calls the cell's
    `systemLayoutSizeFittingSize(:withHorizontalFittingPriority:verticalFittingPriority:)`
    in order to allow the cell to express its desired height given the width of the table view.
    
    But at the start of this call, the UITableViewCell begins with constraints for its
    default width (the screen width) and height (44 points!). This latter constraint is called
    `UIView-Encapsulated-Layout-Height`. Sometimes it appears on the cell, sometimes on the
    contentView. I don't know what rules decides this. If the constraints you have defined on the
    cell are incompiatble with this constraint requiring height==44, then the normal call to
    `systemLayoutSizeFittingSize(:withHorizontalFittingPriority:verticalFittingPriority:)` will emit
    error messages into the console regarding unsatisfiable constraints.
    
    However, these errors are _transient_. On its own, the UITV will later use the value that AL
    calculates for your cell's desired height (as revealed via
    the call to `systemLayoutSizeFittingSize(:withHorizontalFittingPriority:verticalFittingPriority:)`)
    and then reset the `UIView-Encapsulated-Layout-Height` to a value that is compatible with
    your cell's constraints and contents.
    
    ### CONCLUSION
    
    So what?

    The conclusion is, to avoid seeing these spurious warnings messages, you should configure your 
    cell's constraints so that they are compatible with it having a required height of 44. For 
    instance, you could reduce to 999 the priority of the spacer constraint connecting the bottom of
    the contentView to your bottom-most subview within the contentView. This allows that view to 
    poke out beyond the bottom of your contentView, and makes a transient constraint that 
    contentView.height==44 satisfiable.
    
    ### FINDINGS SUMMARY:

    1. height44 constraint invisible outside call to systemLayoutSizeFittingSize(...)
    2. height44 constraint is initalled on the cell not the contentView (in _this_ example...)
    3. non44 constraint on cell => unsatisfiabilility warning
    4. non44 constraint on cell.contentView => no unsatisfiability warning
    5. non44 constraint on cell.contentView.subviews => no unsatisfiability warning

    ### UNANSWERED QUESTIONS:

    1. How does UIKit decide where to put this spurious, transient constraint?
    2. If the `UIView-Encapsulated-Layout-Height` constraint starts out on the contentView, then how
    does `systemLayoutSizeFittingSize(:withHorizontalFittingPriority:verticalFittingPriority:)`
    determine what height the contentView would want to be in the absence of this constraint?
    3. Why is this so complicated?
    

    */
    func height50ConstraintOnView(_ v:UIView) -> NSLayoutConstraint {
      return NSLayoutConstraint(item: v, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 50)
    }

      let heightConstraint:NSLayoutConstraint
      switch location {
      case .cell:
        heightConstraint = height50ConstraintOnView(self)
      case .contentView:
        heightConstraint = height50ConstraintOnView(self.contentView)
      case .contentViewSubview:
        heightConstraint = height50ConstraintOnView(bodyLabel)
      }
      heightConstraint.isActive = true
  }
}


extension ProgCell : TextableLabel {
  func configureWithItem(body:String) -> Void {
    self.bodyLabel.text = body
  }
}



