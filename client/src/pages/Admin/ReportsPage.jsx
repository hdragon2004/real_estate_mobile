import React, { useEffect, useState } from 'react';
import { Layout, Table, Button, Tag, Space, Modal, Descriptions } from 'antd';
import { EyeOutlined } from '@ant-design/icons';
import Sidebar from '../../components/Sidebar';
import axiosPrivate from '../../api/axiosPrivate';
import { unwrapListResponse } from '../../api/responseHelper';
import MessageProvider from '../../components/MessageProvider';

const { Content } = Layout;

const ReportsPage = () => {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [detail, setDetail] = useState(null);
  const { showMessage, contextHolder } = MessageProvider();

  useEffect(() => {
    const fetchReports = async () => {
      try {
        const res = await axiosPrivate.get('/api/admin/reports');
        const reportsData = unwrapListResponse(res);
        setReports(reportsData);
      } catch (error) {
        console.error('Error fetching reports:', error);
        const errorData = error.response?.data;
        const errorMessage = errorData?.message || errorData || 'Không thể tải danh sách báo cáo';
        showMessage.error(errorMessage);
      } finally {
        setLoading(false);
      }
    };
    fetchReports();
  }, []);

  const handleDeletePost = async (postId) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa bài viết này?')) {
      try {
        const response = await axiosPrivate.delete(`/api/admin/posts/${Number(postId)}`);
        if (response.status === 200 || response.status === 204) {
          setReports(reports => reports.filter(r => r.postId !== postId));
          showMessage.success('Đã xoá bài viết thành công');
        }
      } catch (error) {
        console.error('Error deleting post:', error);
        const errorMessage = error.response?.data?.message || error.response?.data || 'Không thể xóa bài viết';
        showMessage.error(errorMessage);
      }
    }
  };

  const columns = [
    { 
      title: 'Bài viết', 
      dataIndex: ['post', 'title'], 
      key: 'post',
      ellipsis: true,
      render: (text, record) => (
        <span style={{ color: '#fff' }}>{text || `Post ID: ${record.postId}`}</span>
      )
    },
    { 
      title: 'Người báo cáo', 
      dataIndex: ['user', 'name'], 
      key: 'user',
      render: (text) => <span style={{ color: '#fff' }}>{text || 'N/A'}</span>
    },
    { 
      title: 'Số điện thoại', 
      dataIndex: 'phone', 
      key: 'phone',
      render: (text) => <span style={{ color: '#fff' }}>{text || 'N/A'}</span>
    },
    { 
      title: 'Lý do', 
      dataIndex: 'type', 
      key: 'type', 
      render: type => <Tag color="red">{type || 'N/A'}</Tag>
    },
    {
      title: 'Hành động',
      key: 'action',
      width: 200,
      render: (_, record) => (
        <Space>
          <Button icon={<EyeOutlined />} onClick={() => setDetail(record)}>Xem</Button>
          <Button danger onClick={() => handleDeletePost(record.postId)}>Xoá bài viết</Button>
        </Space>
      ),
    },
  ];

  return (
    <Layout style={{ minHeight: '100vh' }}>
      {contextHolder}
      <Sidebar selectedKey="/admin/reports" />
      <Layout>
        <Content style={{ margin: '24px 16px 0', background: '#141414' }}>
          <h1 style={{ color: '#fff', fontSize: 24, fontWeight: 700 }}>Quản lý báo cáo</h1>
          <Table columns={columns} dataSource={reports} loading={loading} rowKey="id" style={{ marginTop: 24 }} />
          <Modal 
            open={!!detail} 
            onCancel={() => setDetail(null)} 
            footer={null} 
            title="Chi tiết báo cáo"
            width={600}
          >
            {detail && (
              <Descriptions bordered column={1} size="small">
                <Descriptions.Item label="ID Báo cáo">{detail.id}</Descriptions.Item>
                <Descriptions.Item label="Bài viết">
                  {detail.post?.title || `Post ID: ${detail.postId}`}
                </Descriptions.Item>
                <Descriptions.Item label="Người báo cáo">
                  {detail.user?.name || 'N/A'}
                </Descriptions.Item>
                <Descriptions.Item label="Số điện thoại">
                  {detail.phone || 'N/A'}
                </Descriptions.Item>
                <Descriptions.Item label="Lý do">
                  <Tag color="red">{detail.type || 'N/A'}</Tag>
                </Descriptions.Item>
                <Descriptions.Item label="Mô tả chi tiết">
                  {detail.other || 'Không có mô tả'}
                </Descriptions.Item>
                <Descriptions.Item label="Thời gian">
                  {detail.createdReport ? new Date(detail.createdReport).toLocaleString('vi-VN') : 'N/A'}
                </Descriptions.Item>
                <Descriptions.Item label="Trạng thái">
                  <Tag color={detail.isHandled ? 'green' : 'orange'}>
                    {detail.isHandled ? 'Đã xử lý' : 'Chưa xử lý'}
                  </Tag>
                </Descriptions.Item>
              </Descriptions>
            )}
          </Modal>
        </Content>
      </Layout>
    </Layout>
  );
};

export default ReportsPage; 