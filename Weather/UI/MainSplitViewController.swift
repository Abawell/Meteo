//
//  MainSplitViewController.swift
//  Weather
//
//  Created by Jérôme Cabanis on 10/03/2023.
//

import UIKit

class MainSplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

		delegate = self
		preferredDisplayMode = .allVisible
	}

}

extension MainSplitViewController: UISplitViewControllerDelegate {
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		return true
	}

	@available(iOS 14.0, *)
	func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
		return .primary
	}
}
