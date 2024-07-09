//
//  AppDelegate.swift
//  BackgroundTasksTest
//
//  Created by kyuchul on 7/9/24.
//

import UIKit
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow()
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        
        
        // 모든 Task를 app launch sequence가 끝나기 전에 BGTaskScheduler에 등록
        // 1. Refresh Task 등록
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "example.com", using: nil) { [weak self] task in
            // 2. 실제로 수행할 Background 동작 구현
            self?.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        return true
    }
        
    // 앱이 Background 상태에 들어갈 때 BGTaskScheduler에 Task를 submit
    func applicationDidEnterBackground(_ application: UIApplication) {
        print(#function)
        
        let task = BGAppRefreshTaskRequest(identifier: "example.com")
        
        // 백그라운드 작업을 실행할 때까지의 최소 대기 시간
//        task.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            print("Background Task submit")
            try BGTaskScheduler.shared.submit(task)
            
        } catch {
            print("Could not schedule app refesh")
        }
    }
    
    
}

extension AppDelegate {
    // BackgroundTask를 실제 구현하는 곳에서는 2가지만 기억
    func handleAppRefresh(task: BGAppRefreshTask) {
        
        //  Background Task가 갑자기 종료 되거나 TimeOut 될 때를 대비해서 정의
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                let url = URL(string: "https://baconipsum.com/api/?type=all-meat&paras=1&start-with-lorem=1")!
                let request = URLRequest(url: url)
                async let (data, response) = URLSession.shared.data(for: request)
                guard try await (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw NetworkError.error
                }
                
                let paragraph = try JSONDecoder().decode([String].self, from: try await data)
                print("BackgroundTask 성공 \n\(paragraph[0])")
                // task.setTaskCompleted로 BackgroundTask가 완료함을 확인
                task.setTaskCompleted(success: true)
            } catch {
                // task.setTaskCompleted로 BackgroundTask가 완료함을 확인
                task.setTaskCompleted(success: false)
            }

        }
    }
}

enum NetworkError: Error {
    case error
}
